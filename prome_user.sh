#!/bin/bash

set -e

echo "Starting installation of Prometheus with Basic Auth..."

# Variables
PROM_VERSION="2.45.0"
USER="prometheus"
GROUP="prometheus"
INSTALL_DIR="/etc/prometheus"
DATA_DIR="/var/lib/prometheus"
NGINX_CONF="/etc/nginx/sites-available/prometheus"

# Install dependencies
echo "Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y wget nginx apache2-utils

# Create Prometheus user and group
id -u $USER &>/dev/null || sudo useradd --no-create-home --shell /bin/false $USER

# Download and extract Prometheus
echo "Downloading Prometheus v$PROM_VERSION..."
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v$PROM_VERSION/prometheus-$PROM_VERSION.linux-amd64.tar.gz
tar xvf prometheus-$PROM_VERSION.linux-amd64.tar.gz

# Move binaries
echo "Installing Prometheus binaries..."
cd prometheus-$PROM_VERSION.linux-amd64
sudo mv prometheus promtool /usr/local/bin/
sudo mkdir -p $INSTALL_DIR $DATA_DIR
sudo mv consoles console_libraries $INSTALL_DIR/
sudo mv prometheus.yml $INSTALL_DIR/
sudo chown -R $USER:$GROUP $INSTALL_DIR $DATA_DIR

# Create systemd service
echo "Creating systemd service for Prometheus..."
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=$USER
Group=$GROUP
Type=simple
ExecStart=/usr/local/bin/prometheus \\
  --config.file=$INSTALL_DIR/prometheus.yml \\
  --storage.tsdb.path=$DATA_DIR \\
  --web.console.templates=$INSTALL_DIR/consoles \\
  --web.console.libraries=$INSTALL_DIR/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Reload and start Prometheus
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus

# Create basic auth user
echo "Create a basic auth user for Prometheus."
read -p "Enter username (default: admin): " USERNAME
USERNAME=${USERNAME:-admin}

read -s -p "Enter password for user '$USERNAME': " PASSWORD
echo
read -s -p "Confirm password: " PASSWORD_CONFIRM
echo

if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    echo "❌ Passwords do not match. Exiting."
    exit 1
fi

sudo htpasswd -cb /etc/nginx/.htpasswd "$USERNAME" "$PASSWORD"

# Configure nginx
echo "Configuring nginx for Prometheus reverse proxy with basic auth..."

cat <<EOF | sudo tee $NGINX_CONF
server {
    listen 80;

    server_name _;

    auth_basic "Prometheus Login";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass http://localhost:9090;
    }
}
EOF

sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/prometheus
sudo rm -f /etc/nginx/sites-enabled/default

# Test and restart nginx
sudo nginx -t
sudo systemctl restart nginx

echo "✅ Prometheus is now accessible at: http://<your-server-ip>/"
echo "🔐 Protected with basic auth (username: $USERNAME)"


------------------------------------------------------------------------------------------
for addin the user do this 

sudo htpasswd /etc/nginx/.htpasswd newuser
cat /etc/nginx/.htpasswd

