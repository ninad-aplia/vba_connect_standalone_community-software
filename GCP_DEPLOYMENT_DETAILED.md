# Loop + MeetNote — Detailed GCP Deployment Guide (single VM, Docker Compose)

## 1. Architecture

Loop (NestJS, port 3000) calls MeetNote (FastAPI, port 8000) over internal Docker network.
LiveKit UDP 50000-50020 exposed directly on VM.

## 2. Create the VM
- Machine: e2-medium (2 vCPU, 4 GB RAM)
- Boot disk: 30 GB, Ubuntu 24.04 LTS, Balanced persistent disk
- Data disk: 30 GB, pd-standard
- Firewall: tcp 22,80,443,7880,7881 + udp 50000-50020
- Static external IP

## 3. Create devops user
```bash
sudo adduser --disabled-password --gecos "Loop deploy" devops
sudo usermod -aG sudo devops
sudo mkdir -p /home/devops/.ssh
sudo chmod 700 /home/devops/.ssh
# paste your SSH public key into /home/devops/.ssh/authorized_keys
sudo chown -R devops:devops /home/devops/.ssh
sudo chmod 600 /home/devops/.ssh/authorized_keys
```

## 4. Swap, Docker, data disk
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Install Docker
sudo apt update && sudo apt install -y ca-certificates curl gnupg git
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker devops

# Mount data disk
DATA_DISK=$(lsblk -dpno NAME,TYPE | awk '$2=="disk" && $1!~/sda/ {print $1; exit}')
sudo mkfs.ext4 -F "$DATA_DISK"
sudo mkdir -p /srv
echo "$DATA_DISK /srv ext4 defaults 0 2" | sudo tee -a /etc/fstab
sudo mount -a
sudo mkdir -p /srv/recordings /srv/meetnote /srv/mysql /srv/backups
sudo chown -R devops:devops /srv
```

## 5. Clone repos
```bash
cd /opt
git clone --branch sakshi https://github.com/ninad-aplia/vba_connect_standalone_community-software.git loop
cd /opt/loop
git clone --branch sakshi https://github.com/ninad-aplia/MeetNote.git MeetNote
```

## 6. Configure secrets
```bash
cd /opt/loop/deploy
cp .env.gcp.example .env.gcp
cp livekit.prod.yaml.example livekit.prod.yaml
nano .env.gcp
nano livekit.prod.yaml
chmod 600 .env.gcp livekit.prod.yaml
```

## 7. Launch
```bash
cd /opt/loop/deploy
docker compose -f docker-compose.gcp.yml --env-file .env.gcp up -d --build
```

## 8. Verify
- https://loop.yourdomain.com → Loop login
- https://loop.yourdomain.com/api → Swagger
- https://meetnote-api.yourdomain.com/health → {"status":"ok"}

## 9. Create MeetNote service account user
Register user matching MEETNOTE_SERVICE_EMAIL/PASSWORD in MeetNote UI.

## 10. Troubleshooting
See GCP_DEPLOY_RUNBOOK.md
EOF
echo "Done"
