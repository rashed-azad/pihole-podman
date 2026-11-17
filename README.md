# Pi-hole on rootless Podman (Linux Mint)

Pi-hole runs as your normal user. Only two one-time steps need sudo:
installing Podman and allowing port 53.

## Setup on a new machine
```bash
./setup-host.sh                   # once, asks for sudo
cp pihole.env.example pihole.env  # set your password
./install.sh                      # no sudo (auto-detects LAN IP)
```
- Web UI: http://localhost:8080/admin
- Give this laptop a fixed IP in your router, then set that IP as DNS server.

## Restore old settings
Web UI → Settings → Teleporter → Import your `.zip` backup.

## Daily use
| Task      | Command |
|-----------|---------|
| Status    | `systemctl --user status pihole` |
| Logs      | `journalctl --user -u pihole -f` |
| Restart   | `systemctl --user restart pihole` |
| Update    | `./install.sh` |
| Backup    | `./backup.sh` |
| Remove    | `./uninstall.sh` (add `--purge` to delete data) |
| Test      | `dig @<LAN-IP> doubleclick.net` (should return 0.0.0.0) |

## Notes
- Pi-hole starts when you log in. To start at boot without login (optional, needs sudo):
  `loginctl enable-linger`
- If your LAN IP changes, run `./install.sh` again.
- Needs Podman 4.4 or newer (`podman --version`). Mint 22 has 4.9.

## Where things live
- Service file: `~/.config/containers/systemd/pihole.container`
- Password: `~/.config/pihole/pihole.env`
- Data: `~/.local/share/pihole/etc-pihole`
