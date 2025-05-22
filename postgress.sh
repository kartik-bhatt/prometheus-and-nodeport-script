#!/bin/bash
set -e

# === CONFIGURABLE ===
POSTGRES_PASSWORD="StrongPostgresPassword123"
EXPORTER_USER="postgres_exporter"
EXPORTER_PASSWORD="ExporterPass123"
EXPORTER_PORT=9008

echo "=== Installing PostgreSQL ==="
apt update
apt install -y wget gnupg2 lsb-release postgresql postgresql-contrib

echo "=== Configuring PostgreSQL password ==="
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}';"

echo "=== Updating pg_hba.conf for password authentication ==="
PG_HBA=$(sudo -u postgres psql -c "SHOW hba_file;" -tA)
sed -i 's/^local\s\+all\s\+postgres\s\+peer/local all postgres md5/' "$PG_HBA"
sed -i 's/^local\s\+all\s\+all\s\+peer/local all all md5/' "$PG_HBA"

echo "=== Restarting PostgreSQL ==="
systemctl restart postgresql

echo "=== Creating exporter user ==="
sudo -u postgres psql -c "CREATE USER ${EXPORTER_USER} WITH PASSWORD '${EXPORTER_PASSWORD}' LOGIN;"
sudo -u postgres psql -c "GRANT CONNECT ON DATABASE postgres TO ${EXPORTER_USER};"
sudo -u postgres psql -c "GRANT USAGE ON SCHEMA public TO ${EXPORTER_USER};"
sudo -u postgres psql -d postgres -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${EXPORTER_USER};"
sudo -u postgres psql -d postgres -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ${EXPORTER_USER};"

echo "=== Downloading PostgreSQL Exporter ==="
useradd -rs /bin/false postgres_exporter || true
cd /opt
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v0.15.0/postgres_exporter-0.15.0.linux-amd64.tar.gz
tar -xvf postgres_exporter-0.15.0.linux-amd64.tar.gz
mv postgres_exporter-0.15.0.linux-amd64 postgres_exporter
chown -R postgres_exporter:postgres_exporter /opt/postgres_exporter

echo "=== Creating exporter environment file ==="
cat <<EOF > /etc/default/postgres_exporter
DATA_SOURCE_NAME="postgresql://${EXPORTER_USER}:${EXPORTER_PASSWORD}@localhost:5432/postgres?sslmode=disable"
EOF
chown postgres_exporter:postgres_exporter /etc/default/postgres_exporter

echo "=== Creating systemd service ==="
cat <<EOF > /etc/systemd/system/postgres_exporter.service
[Unit]
Description=PostgreSQL Exporter
After=network.target

[Service]
User=postgres_exporter
Group=postgres_exporter
EnvironmentFile=/etc/default/postgres_exporter
ExecStart=/opt/postgres_exporter/postgres_exporter --web.listen-address=":${EXPORTER_PORT}"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "=== Starting PostgreSQL Exporter ==="
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now postgres_exporter

echo "=== DONE ==="
echo "Visit http://localhost:${EXPORTER_PORT}/metrics to confirm metrics are working"

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
After that

sudo sed -i 's/^\(local\s\+all\s\+postgres\s\+\)md5/\1peer/' /etc/postgresql/16/main/pg_hba.conf


sudo systemctl restart postgresql
sudo -u postgres psql
ALTER USER postgres WITH PASSWORD 'PostgresPass123!';
\q

sudo sed -i 's/^\(local\s\+all\s\+postgres\s\+\)peer/\1md5/' /etc/postgresql/16/main/pg_hba.conf
sudo systemctl restart postgresql

PGPASSWORD="PostgresPass123!" psql -U postgres -h localhost -d postgres -c '\l'





