#!/usr/bin/env bash
# One-time system setup. The ONLY two sudo steps.
set -euo pipefail

# 1. Install Podman (skipped if already installed)
if ! command -v podman >/dev/null; then
  sudo apt update && sudo apt install -y podman
fi

# 2. Allow normal users to open port 53 (DNS), and disable IPv6 on this
#    machine. Affects the whole host, not just Pi-hole — remove the ipv6
#    lines below (and the file) to re-enable. Pi-hole itself is also told
#    to stop handing out AAAA answers, see pihole.container.in.
sudo tee /etc/sysctl.d/99-pihole.conf >/dev/null <<'EOF'
net.ipv4.ip_unprivileged_port_start=53
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF
sudo sysctl --system >/dev/null

echo "Done. Now run ./install.sh (no sudo)."
