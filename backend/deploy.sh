#!/bin/bash
# =============================================================================
# OFG Connects – Oracle Cloud (Ubuntu 22.04) One-Shot Deployment Script
# Run this as: bash deploy.sh
# =============================================================================

set -e  # Exit on any error

echo "========================================"
echo "  OFG Connects Backend Deployment"
echo "========================================"

# ---- 1. System update -------------------------------------------------------
echo "[1/8] Updating system..."
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y python3 python3-pip python3-venv git ufw nginx

# ---- 2. Firewall ------------------------------------------------------------
echo "[2/8] Configuring firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw allow 8787/tcp
sudo ufw --force enable

# ---- 3. App directory -------------------------------------------------------
echo "[3/8] Setting up app directory..."
sudo mkdir -p /opt/ofg
sudo chown -R ubuntu:ubuntu /opt/ofg

# ---- 4. Copy files (run from your local machine via SCP first) -------------
echo "[4/8] Creating Python virtual environment..."
cd /opt/ofg
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install boto3==1.35.0 botocore==1.35.0 python-dotenv==1.0.1

# ---- 5. Systemd service -----------------------------------------------------
echo "[5/8] Creating systemd service..."
sudo tee /etc/systemd/system/ofg-backend.service > /dev/null <<EOF
[Unit]
Description=OFG Connects Backend API
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/opt/ofg
Environment=PATH=/opt/ofg/venv/bin
ExecStart=/opt/ofg/venv/bin/python server.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ofg-backend
sudo systemctl start ofg-backend

# ---- 6. Nginx reverse proxy -------------------------------------------------
echo "[6/8] Configuring Nginx..."
sudo tee /etc/nginx/sites-available/ofg > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    client_max_body_size 500M;
    
    location / {
        proxy_pass http://127.0.0.1:8787;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 300s;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/ofg /etc/nginx/sites-enabled/ofg
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

# ---- 7. Status check --------------------------------------------------------
echo "[7/8] Checking service status..."
sleep 3
sudo systemctl status ofg-backend --no-pager

# ---- 8. Done ----------------------------------------------------------------
echo ""
echo "========================================"
echo "  DEPLOYMENT COMPLETE!"
echo "========================================"
echo "  API running at: http://$(curl -s ifconfig.me):80"
echo "  Service logs: sudo journalctl -u ofg-backend -f"
echo "  Restart: sudo systemctl restart ofg-backend"
echo "========================================"
