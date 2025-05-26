Script 1: Install and Configure PostgreSQL

#!/bin/bash

set -e

# Configuration
POSTGRES_USER="admin"
POSTGRES_PASSWORD="admin"
POSTGRES_DB="mydatabase"

# Update and install PostgreSQL
echo "Installing PostgreSQL..."
sudo apt update
sudo apt install -y postgresql postgresql-contrib

# Enable and start PostgreSQL
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Configure PostgreSQL user and database
echo "Configuring PostgreSQL..."

sudo -u postgres psql <<EOF
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = '${POSTGRES_USER}') THEN
      CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
   END IF;
END
\$do\$;

CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};
GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};
EOF

echo "PostgreSQL installed and configured successfully."


------------------------------------------------------------------------------------------------------------------------------

✅ Script 2: Install and Configure PostgreSQL Exporter

#!/bin/bash

set -e

# Configuration
EXPORTER_VERSION="0.15.0"
POSTGRES_USER="admin"
POSTGRES_PASSWORD="admin"
DATA_SOURCE_NAME="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/postgres?sslmode=disable"

# Download PostgreSQL Exporter
echo "Installing PostgreSQL Exporter..."
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v${EXPORTER_VERSION}/postgres_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz

tar -xzf postgres_exporter-${EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv postgres_exporter-${EXPORTER_VERSION}.linux-amd64/postgres_exporter /usr/local/bin/
rm -rf postgres_exporter-${EXPORTER_VERSION}.linux-amd64*

# Create postgres_exporter user in PostgreSQL
echo "Creating monitoring user in PostgreSQL..."
sudo -u postgres psql <<EOF
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'postgres_exporter') THEN
      CREATE USER postgres_exporter PASSWORD '${POSTGRES_PASSWORD}';
      GRANT CONNECT ON DATABASE postgres TO postgres_exporter;
      GRANT USAGE ON SCHEMA public TO postgres_exporter;
      GRANT SELECT ON ALL TABLES IN SCHEMA public TO postgres_exporter;
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO postgres_exporter;
   END IF;
END
\$do\$;
EOF

# Create systemd service
echo "Setting up systemd service for postgres_exporter..."
cat <<EOF | sudo tee /etc/systemd/system/postgres_exporter.service
[Unit]
Description=Prometheus PostgreSQL Exporter
After=network.target

[Service]
User=postgres
Environment=DATA_SOURCE_NAME=${DATA_SOURCE_NAME}
ExecStart=/usr/local/bin/postgres_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload and start service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable postgres_exporter
sudo systemctl start postgres_exporter

echo "PostgreSQL Exporter installed and running on port 9187."
