#!/usr/bin/env bash
# Install or update Pi-hole as a rootless user service. No sudo.
# Usage: ./install.sh [LAN_IP]   (default: auto-detect)
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f pihole.env ]; then
  echo "Missing pihole.env. Run: cp pihole.env.example pihole.env  (then set the password)"
  exit 1
fi

IP="${1:-$(ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')}"
[ -n "$IP" ] || { echo "Could not detect LAN IP. Run: ./install.sh 192.168.x.x"; exit 1; }
echo "Using LAN IP: $IP"

mkdir -p ~/.config/containers/systemd ~/.config/pihole ~/.local/share/pihole/etc-pihole
sed "s/@PIHOLE_IP@/$IP/g" pihole.container.in > ~/.config/containers/systemd/pihole.container
install -m 600 pihole.env ~/.config/pihole/pihole.env

podman pull docker.io/pihole/pihole:latest
systemctl --user daemon-reload
systemctl --user restart pihole.service

echo "Waiting for Pi-hole to start..."
sleep 15
if dig +short +time=3 @"$IP" google.com | grep -q .; then
  echo "OK: DNS works. Web UI: http://$IP:8080/admin  DNS: $IP"
else
  echo "ERROR: DNS test failed. Check: journalctl --user -u pihole -n 50"
  exit 1
fi