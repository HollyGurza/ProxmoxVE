#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster) | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.qbittorrent.org/ | Github: https://github.com/qbittorrent/qBittorrent

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
QB_PASS=$(random_password 20)
QB_SALT=$(random_password 16)
QB_HASH="$(printf '%s' "$QB_SALT" | base64 -w0):$(openssl kdf -keylen 64 -kdfopt digest:SHA512 -kdfopt pass:"$QB_PASS" -kdfopt salt:"$QB_SALT" -kdfopt iter:100000 -binary PBKDF2 | base64 -w0)"
{
  echo "qBittorrent Credentials"
  echo "Username: admin"
  echo "Password: ${QB_PASS}"
} >~/qbittorrent.creds
cat <<EOF >/home/qbittorrent/.config/qBittorrent/qBittorrent.conf
[LegalNotice]
Accepted=true

[Preferences]
WebUI\Password_PBKDF2="@ByteArray(${QB_HASH})"
WebUI\Port=8090
WebUI\UseUPnP=false
WebUI\Username=admin

[Network]
PortForwardingEnabled=false
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
cleanup_lxc
