#!/usr/bin/env bash
# One-time system setup. The ONLY two sudo steps.
set -euo pipefail

# 1. Install Podman (skipped if already installed)
if ! command -v podman >/dev/null; then
  sudo apt update && sudo apt install -y podman
fi

# 2. Allow normal users to open port 53 (DNS)
echo 'net.ipv4.ip_unprivileged_port_start=53' | sudo tee /etc/sysctl.d/99-pihole.conf >/dev/null
sudo sysctl --system >/dev/null

echo "Done. Now run ./install.sh (no sudo)."
