#!/bin/bash

# Exit immediately if a command fails
set -e

# Variables
EXPORTER_VERSION="0.15.1"
USER="mysql_exporter"
PASSWORD="secure_password_here"  # <-- Change this!
MYSQL_USER="exporter"
MYSQL_PASS="exporter_password"   # <-- Change this!
DATA_DIR="/opt/mysql_exporter"

# Create MySQL user for exporter
echo "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASS';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO '$MYSQL_USER'@'localhost';" | sudo mysql -u root

# Create exporter system user
sudo useradd -rs /bin/false $USER || true

# Create data directory
sudo mkdir -p $DATA_DIR
cd $DATA_DIR

# Download and extract mysqld_exporter
wget https://github.com/prometheus/mysqld_exporter/releases/download/v${EXPORTER_VERSION}/mysqld_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvf mysqld_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv mysqld_exporter-${EXPORTER_VERSION}.linux-amd64/mysqld_exporter /usr/local/bin/
rm -rf mysqld_exporter-${EXPORTER_VERSION}.linux-amd64*

# Create .my.cnf config file
cat <<EOF | sudo tee /etc/.mysqld_exporter.cnf
[client]
user=$MYSQL_USER
password=$MYSQL_PASS
EOF
sudo chown $USER:$USER /etc/.mysqld_exporter.cnf
sudo chmod 600 /etc/.mysqld_exporter.cnf

# Create systemd service
cat <<EOF | sudo tee /etc/systemd/system/mysqld_exporter.service
[Unit]
Description=MySQL Exporter for Prometheus
After=network.target

[Service]
User=$USER
Group=$USER
Type=simple
ExecStart=/usr/local/bin/mysqld_exporter \\
  --config.my-cnf=/etc/.mysqld_exporter.cnf \\
  --web.listen-address=":9104"

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable mysqld_exporter
sudo systemctl start mysqld_exporter

echo "MySQL Exporter installed and running on port 9104."
