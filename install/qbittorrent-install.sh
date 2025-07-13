#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tteck (tteckster) | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.qbittorrent.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Create qbittorrent user"
if ! id -u qbittorrent >/dev/null 2>&1; then
  useradd -u 1000 -m -s /usr/sbin/nologin qbittorrent
  msg_ok "User qbittorrent created"
else
  msg_ok "User qbittorrent already exists"
fi

msg_info "Setup qBittorrent-nox"
$STD apt-get install -y qbittorrent-nox
mkdir -p /home/qbittorrent/.config/qBittorrent/
cat <<EOF >/home/qbittorrent/.config/qBittorrent/qBittorrent.conf
[LegalNotice]
Accepted=true

[Preferences]
WebUI\Password_PBKDF2="@ByteArray(amjeuVrF3xRbgzqWQmes5A==:XK3/Ra9jUmqUc4RwzCtrhrkQIcYczBl90DJw2rT8DFVTss4nxpoRhvyxhCf87ahVE3SzD8K9lyPdpyUCfmVsUg==)"
WebUI\Port=8090
WebUI\UseUPnP=false
WebUI\Username=admin
EOF
msg_ok "Setup qBittorrent-nox"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/qbittorrent-nox.service
[Unit]
Description=qBittorrent client
After=network.target
[Service]
User=qbittorrent
Group=qbittorrent
Type=simple
ExecStart=/usr/bin/qbittorrent-nox
Restart=always
[Install]
WantedBy=multi-user.target
EOF
chown -R qbittorrent:qbittorrent /home/qbittorrent/
systemctl enable -q --now qbittorrent-nox
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
