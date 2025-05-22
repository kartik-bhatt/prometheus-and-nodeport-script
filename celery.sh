#!/bin/bash

set -e

echo "📦 Updating system packages..."
sudo apt-get update -y

echo "🐍 Installing Python3, pip, and virtualenv..."
sudo apt-get install -y python3 python3-pip python3-venv

echo "🚀 Creating virtual environment for Celery Exporter..."
python3 -m venv celery_exporter_env
source celery_exporter_env/bin/activate

echo "⬆️ Upgrading pip, setuptools, and wheel..."
pip install --upgrade pip setuptools wheel

echo "📥 Installing Celery, Prometheus client, and Celery Prometheus Exporter..."
pip install celery prometheus_client celery-prometheus-exporter

echo "⚙️ Creating the Celery Exporter startup script..."
cat <<EOL > start_celery_exporter.sh
#!/bin/bash
source celery_exporter_env/bin/activate

celery-prometheus-exporter \\
  --addr 0.0.0.0:9540 \\
  --broker redis://localhost:6379/0 \\
  --enable-events \\
  --verbose
EOL

chmod +x start_celery_exporter.sh

echo "✅ Celery Prometheus Exporter installed successfully."
echo "➡️ Run './start_celery_exporter.sh' to start the exporter."
echo "🌐 Visit 'http://<your-server-ip>:8888/metrics' to access Prometheus metrics."



After that change in the start_celery_exporter.sh

#!/bin/bash

# Exit on any error
set -e

# Create virtual environment if not already present
if [ ! -d "celery_exporter_env" ]; then
    echo "[*] Creating virtual environment..."
    python3 -m venv celery_exporter_env
fi

# Activate the virtual environment
source celery_exporter_env/bin/activate

# Upgrade pip
echo "[*] Upgrading pip..."
pip install --upgrade pip

# Install necessary Python packages
echo "[*] Installing dependencies..."
pip install celery redis celery-prometheus-exporter

# Export environment variables for Celery config
export CELERY_BROKER_URL=redis://localhost:6379/0
export CELERY_RESULT_BACKEND=redis://localhost:6379/0
export CELERY_APP=proj  # Replace 'proj' with your actual Celery app name if different

# Start the Celery Prometheus Exporter
echo "[*] Starting Celery Prometheus Exporter on port 8888..."
python3 -m celery_prometheus_exporter
