#!/usr/bin/env bash
# Stop and remove the service. Keeps your data unless you pass --purge.
set -euo pipefail
systemctl --user stop pihole.service 2>/dev/null || true
rm -f ~/.config/containers/systemd/pihole.container
systemctl --user daemon-reload
if [ "${1:-}" = "--purge" ]; then
  podman unshare rm -rf ~/.local/share/pihole ~/.config/pihole
  echo "Removed service and data."
else
  echo "Removed service. Data kept in ~/.local/share/pihole"
fi
