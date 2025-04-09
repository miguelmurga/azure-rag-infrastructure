#!/bin/bash

# Variables son automáticamente reemplazadas por Terraform
CHROMADB_API_KEY="${CHROMADB_API_KEY}"
USERNAME="${username}"

# Actualizar e instalar paquetes
apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2 fail2ban unattended-upgrades auditd rkhunter chkrootkit podman-compose nginx certbot python3-certbot-nginx ufw

# Crear directorio para certificados SSL
mkdir -p /etc/nginx/ssl

# Configurar UFW
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow https
ufw --force enable

# Configurar fail2ban
cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[sshd-ddos]
enabled = true
port = 22
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 2
bantime = 86400
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Configurar endurecimiento SSH
cat > /etc/ssh/sshd_config <<EOF
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
UsePrivilegeSeparation yes
KeyRegenerationInterval 3600
ServerKeyBits 2048
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 30
PermitRootLogin no
StrictModes yes
RSAAuthentication yes
PubkeyAuthentication yes
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication no
X11Forwarding no
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
UsePAM yes
MaxAuthTries 3
MaxSessions 2
EOF

systemctl restart sshd

# Configurar actualizaciones automáticas de seguridad
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "Ubuntu:jammy";
    "Ubuntu:jammy-security";
    "Ubuntu:jammy-updates";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Mail "root";
Unattended-Upgrade::MailOnlyOnError "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Crear directorio para ChromaDB
mkdir -p /home/$USERNAME/chroma-storage
chown $USERNAME:$USERNAME /home/$USERNAME/chroma-storage

# Configurar Podman para ChromaDB
cat > /home/$USERNAME/docker-compose.yml <<EOF
version: '3.8'

services:
  chromadb:
    image: ghcr.io/chroma-core/chroma:0.4.15
    container_name: chromadb
    environment:
      - CHROMA_SERVER_AUTH_CREDENTIALS_ENABLE=true
      - CHROMA_SERVER_AUTH_CREDENTIALS_TOKEN=$CHROMADB_API_KEY
      - CHROMA_SERVER_AUTH_PROVIDER=token
    volumes:
      - /home/$USERNAME/chroma-storage:/chroma/chroma
    ports:
      - "8000:8000"
    restart: always
EOF

# Dar permisos al usuario
chown $USERNAME:$USERNAME /home/$USERNAME/docker-compose.yml

# Configurar Nginx como proxy inverso con HTTPS
cat > /etc/nginx/sites-available/chromadb <<'EOF'
server {
    listen 80;
    server_name _;

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name _;

    ssl_certificate /etc/nginx/ssl/certificate.crt;
    ssl_certificate_key /etc/nginx/ssl/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -s /etc/nginx/sites-available/chromadb /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Generar certificado autofirmado para la configuración inicial
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/private.key \
    -out /etc/nginx/ssl/certificate.crt \
    -subj "/C=US/ST=State/L=City/O=RAG Infrastructure/OU=IT/CN=$(hostname)"

# Iniciar Podman con ChromaDB (como usuario normal, no root)
su - $USERNAME -c "cd /home/$USERNAME && podman-compose up -d"

# Iniciar Nginx
systemctl enable nginx
systemctl restart nginx

# Configurar reglas auditd
cat > /etc/audit/rules.d/audit.rules <<EOF
# Eliminar reglas existentes
-D

# Aumentar los buffers para sobrevivir a eventos de estrés
-b 8192

# Monitorizar intentos de acceso no autorizados
-w /var/log/auth.log -p wa -k auth_log
-w /var/log/syslog -p wa -k syslog

# Monitorizar montajes del sistema de archivos
-a exit,always -F arch=b64 -S mount -S umount2 -k mount

# Monitorizar cambios en la configuración de autenticación
-w /etc/pam.d/ -p wa -k pam
-w /etc/nsswitch.conf -p wa -k nsswitch

# Monitorizar cambios en la configuración SSH
-w /etc/ssh/sshd_config -p wa -k sshd_config

# Monitorizar cambios en la configuración del sistema
-w /etc/security/ -p wa -k security
-w /etc/sudoers -p wa -k sudoers

# Monitorizar gestión de usuarios y grupos
-w /usr/sbin/useradd -p x -k user_modification
-w /usr/sbin/userdel -p x -k user_modification
-w /usr/sbin/usermod -p x -k user_modification
-w /usr/sbin/groupadd -p x -k group_modification
-w /usr/sbin/groupdel -p x -k group_modification
-w /usr/sbin/groupmod -p x -k group_modification

# Monitorizar cambios de fecha/hora
-a exit,always -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -k time-change

# Hacer que la configuración sea inmutable - requiere reinicio para cambiar
-e 2
EOF

# Reiniciar auditd
systemctl restart auditd

# Programar escaneos de seguridad
echo "0 2 * * * root /usr/bin/rkhunter --check --skip-keypress --report-warnings-only" > /etc/cron.d/rkhunter
echo "0 3 * * * root /usr/sbin/chkrootkit" > /etc/cron.d/chkrootkit

echo "Configuración completada correctamente"
