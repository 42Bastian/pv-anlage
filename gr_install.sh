
#!/bin/bash

apt install -y apt-transport-https software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
apt update
apt -y install grafana

systemctl daemon-reload
systemctl enable grafana-server.service
systemctl start grafana-server.service

# Web: http://localhost:3000/login (admin/admin)

