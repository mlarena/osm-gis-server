# Остановите текущий процесс Martin (Ctrl+C)

# Создайте файл сервиса
sudo tee /etc/systemd/system/martin.service << 'EOF'
[Unit]
Description=Martin Tile Server
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/tmp
Environment="DATABASE_URL=postgresql://postgres:12345678@localhost:5432/gis"
ExecStart=/usr/bin/martin --webui enable-for-all
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Перезагрузите systemd и запустите службу
sudo systemctl daemon-reload
sudo systemctl start martin
sudo systemctl enable martin

# Проверьте статус
sudo systemctl status martin