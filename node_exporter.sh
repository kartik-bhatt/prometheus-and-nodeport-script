#!/bin/bash

set -e

# Variables
NODE_EXPORTER_VERSION="1.8.1"
USER="node_exporter"
GROUP="node_exporter"
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"

echo "🔧 Creating node_exporter user..."
sudo useradd --no-create-home --shell /bin/false $USER || true

echo "⬇️ Downloading Node Exporter v$NODE_EXPORTER_VERSION..."
cd /tmp
curl -sLO https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
tar -xzf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz

echo "📦 Installing Node Exporter binary..."
cd node_exporter-$NODE_EXPORTER_VERSION.linux-amd64
sudo cp node_exporter $INSTALL_DIR/
sudo chown $USER:$GROUP $INSTALL_DIR/node_exporter

echo "📝 Creating systemd service file..."
cat <<EOF | sudo tee $SERVICE_FILE
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=$USER
Group=$GROUP
Type=simple
ExecStart=$INSTALL_DIR/node_exporter

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Reloading systemd and starting Node Exporter..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

echo "✅ Node Exporter installed and running on port 9100"
echo "👉 Access it at: http://<your-ec2-ip>:9100/metrics"
