#!/bin/bash

set -e

# Variables
REDIS_EXPORTER_VERSION="1.46.0"   # You can update to latest version if needed
USER="redis_exporter"
DATA_DIR="/opt/redis_exporter"

# Create redis_exporter user (no login shell)
sudo useradd --no-create-home --shell /bin/false $USER || true

# Create directory for redis_exporter
sudo mkdir -p $DATA_DIR

# Download Redis Exporter binary
cd /tmp
wget https://github.com/oliver006/redis_exporter/releases/download/v${REDIS_EXPORTER_VERSION}/redis_exporter-v${REDIS_EXPORTER_VERSION}.linux-amd64.tar.gz

# Extract binary
tar xzf redis_exporter-v${REDIS_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv redis_exporter-v${REDIS_EXPORTER_VERSION}.linux-amd64/redis_exporter /usr/local/bin/

# Cleanup
rm -rf redis_exporter-v${REDIS_EXPORTER_VERSION}.linux-amd64*

# Set ownership and permissions
sudo chown $USER:$USER /usr/local/bin/redis_exporter

# Create systemd service file
sudo tee /etc/systemd/system/redis_exporter.service > /dev/null <<EOF
[Unit]
Description=Redis Exporter
After=network.target

[Service]
User=$USER
Group=$USER
Type=simple
ExecStart=/usr/local/bin/redis_exporter \\
  --web.listen-address=":9121" \\
  --redis.addr="redis://localhost:6379"

Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable redis_exporter
sudo systemctl start redis_exporter

echo "Redis Exporter installed and running on port 9121."
