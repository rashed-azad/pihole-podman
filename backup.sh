#!/usr/bin/env bash
# Save Pi-hole data to backups/ (git-ignored: contains password hash).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p backups
f="backups/etc-pihole-$(date +%F).tar.gz"
podman unshare tar -czf "$f" -C ~/.local/share/pihole etc-pihole
echo "Saved $f"
