# Pi-hole on rootless Podman (Linux Mint)

Pi-hole runs as your normal user. Only two one-time steps need sudo:
installing Podman and allowing port 53.

## Setup on a new machine
```bash
./setup-host.sh                   # once, asks for sudo
cp pihole.env.example pihole.env  # set your password
./install.sh                      # no sudo (auto-detects LAN IP)
```
- Web UI: http://<LAN-IP>:8080/admin (not `localhost` — the Web UI is scoped to your LAN IP only, same as DNS, so it isn't reachable from other networks this laptop joins)
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
| Add blocklists | `./add-blocklists.sh` (ads/trackers/malware + adult content, see below) |
| Remove    | `./uninstall.sh` (add `--purge` to delete data) |
| Test      | `dig @<LAN-IP> doubleclick.net` (should return 0.0.0.0) |

## Blocklists
`./add-blocklists.sh` adds two curated lists via the Pi-hole API (idempotent, safe to re-run):
- **Hagezi Multi** — ads, trackers, malware, phishing, scams
- **Hagezi NSFW** — adult content

These apply network-wide to every device using this Pi-hole as DNS, not just this machine. Review under Web UI (http://<LAN-IP>:8080/admin) → Adlists, and check Query Log if a site breaks unexpectedly — disable the specific list there rather than guessing.

Optional add-on: Hagezi also publishes a **Gambling** list (`adblock/gambling.txt`, or the smaller `.medium`/`.mini` variants — the full one is ~650k entries and noticeably bigger than Multi+NSFW combined). Not added by default since it wasn't asked for; add it to the `LISTS` array in `add-blocklists.sh` if you want it.

## IPv6
- `setup-host.sh` disables IPv6 on the host machine (`net.ipv6.conf.*.disable_ipv6=1`). This is host-wide, not Pi-hole-specific — revert by deleting `/etc/sysctl.d/99-pihole.conf` and re-running `sysctl --system`.
- `pihole.container.in` additionally sets `FTLCONF_misc_dnsmasq_lines=filter-AAAA`, so Pi-hole itself never hands LAN clients an IPv6 (AAAA) answer. This is the part that actually matters for DNS behavior — the host sysctl alone doesn't stop clients from querying for or receiving AAAA records.
- Both are new since the last install — re-run `./setup-host.sh` and `./install.sh` to apply them.

## Notes
- Pi-hole starts when you log in. To start at boot without login (optional, needs sudo):
  `loginctl enable-linger`
- If your LAN IP changes, run `./install.sh` again.
- Needs Podman 4.4 or newer (`podman --version`). Mint 22 has 4.9.

## Where things live
- Service file: `~/.config/containers/systemd/pihole.container`
- Password: `~/.config/pihole/pihole.env`
- Data: `~/.local/share/pihole/etc-pihole`
