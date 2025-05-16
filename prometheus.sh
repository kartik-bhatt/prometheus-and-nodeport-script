#!/bin/bash

set -e

# Variables
PROM_VERSION="2.52.0"
USER="prometheus"
GROUP="prometheus"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/prometheus"
DATA_DIR="/var/lib/prometheus"
SERVICE_FILE="/etc/systemd/system/prometheus.service"

echo "🔧 Creating Prometheus user..."
sudo useradd --no-create-home --shell /bin/false $USER || true

echo "📁 Creating directories..."
sudo mkdir -p $CONFIG_DIR $DATA_DIR
sudo chown -R $USER:$GROUP $CONFIG_DIR $DATA_DIR

echo "⬇️ Downloading Prometheus v$PROM_VERSION..."
cd /tmp
curl -sLO https://github.com/prometheus/prometheus/releases/download/v$PROM_VERSION/prometheus-$PROM_VERSION.linux-amd64.tar.gz
tar -xzf prometheus-$PROM_VERSION.linux-amd64.tar.gz

cd prometheus-$PROM_VERSION.linux-amd64

echo "📦 Installing Prometheus binaries..."
sudo cp prometheus promtool $INSTALL_DIR
sudo chown $USER:$GROUP $INSTALL_DIR/prometheus $INSTALL_DIR/promtool

echo "📦 Copying config and consoles..."
sudo cp -r consoles console_libraries $CONFIG_DIR
sudo cp prometheus.yml $CONFIG_DIR
sudo chown -R $USER:$GROUP $CONFIG_DIR

echo "📝 Creating Prometheus systemd service..."
cat <<EOF | sudo tee $SERVICE_FILE
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=$USER
Group=$GROUP
Type=simple
ExecStart=$INSTALL_DIR/prometheus \\
  --config.file=$CONFIG_DIR/prometheus.yml \\
  --storage.tsdb.path=$DATA_DIR \\
  --web.console.templates=$CONFIG_DIR/consoles \\
  --web.console.libraries=$CONFIG_DIR/console_libraries

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Reloading systemd and starting Prometheus..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

echo "✅ Prometheus installation complete. Access it at: http://<your-ec2-ip>:9090"
