#!/bin/bash
# EcoAlert Backend — Oracle Cloud ARM Ubuntu 22.04 setup script
# Run once as ubuntu user: bash oracle_setup.sh

set -e

echo "=== [1/6] System update ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3.11 python3.11-venv python3-pip nginx certbot python3-certbot-nginx git ufw

echo "=== [2/6] Firewall ==="
sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 5000
sudo ufw --force enable

echo "=== [3/6] Clone repo ==="
cd /home/ubuntu
if [ ! -d "EcoAlert" ]; then
  git clone https://github.com/Barii1/EcoAlert.git
fi
cd EcoAlert
git pull origin main

echo "=== [4/6] Python venv + dependencies ==="
cd /home/ubuntu/EcoAlert/backend/ecoalert-backend
python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "=== [5/6] Create .env (you must fill in real values) ==="
if [ ! -f ".env" ]; then
  cp .env.example .env
  echo ""
  echo ">>> IMPORTANT: Edit /home/ubuntu/EcoAlert/backend/ecoalert-backend/.env with your real keys <<<"
  echo ">>> Run: nano /home/ubuntu/EcoAlert/backend/ecoalert-backend/.env"
fi

echo "=== [6/6] systemd service ==="
sudo tee /etc/systemd/system/ecoalert.service > /dev/null <<EOF
[Unit]
Description=EcoAlert Flask Backend
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/EcoAlert/backend/ecoalert-backend
EnvironmentFile=/home/ubuntu/EcoAlert/backend/ecoalert-backend/.env
ExecStart=/home/ubuntu/EcoAlert/backend/ecoalert-backend/venv/bin/uvicorn app:asgi_app --host 0.0.0.0 --port 5000 --workers 2
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ecoalert

echo ""
echo "======================================================"
echo " Setup complete. Next steps:"
echo " 1. Edit .env:  nano /home/ubuntu/EcoAlert/backend/ecoalert-backend/.env"
echo " 2. Upload image model via SCP (see README)"
echo " 3. Start service: sudo systemctl start ecoalert"
echo " 4. Check status:  sudo systemctl status ecoalert"
echo " 5. View logs:     sudo journalctl -u ecoalert -f"
echo "======================================================"
