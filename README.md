# kindle

Setup for a jailbroken Kindle Paperwhite 2 (6th generation, serial prefix
905A) that boots straight into KOReader, with the stock Amazon framework
removed and Tailscale for remote access.

## Device state

| Component | Version |
|---|---|
| Firmware | 5.12.2.2, the final release for the PW2 |
| Jailbreak hotfix | 2.5.0 ([KindleModding/Hotfix](https://github.com/KindleModding/Hotfix)) |
| KOReader | v2026.07.1, `kindlepw2` build |
| UI plugin | [Simple UI](https://github.com/doctorhetfield-cmd/simpleui.koplugin) 3.0.3 |
| USBNetwork | 0.22.N (NiLuJe), used only for dropbear |
| Tailscale | 1.104.5, static `arm` build, userspace networking |

## Layout

- `device/install.sh` runs on the Kindle as root. It deletes the upstart jobs
  in `drop-jobs.txt`, the files in `drop-files.txt` and the libraries in
  `drop-libs.txt`, installs the jobs under `device/etc/upstart/`, removes the
  `demd` dependency from `lab126.conf`, strips Amazon's logging cron entries
  and appends `hosts.block` to `/etc/hosts`.
- `device/etc/upstart/koreader.conf` starts KOReader once `volumd` and `wifid`
  are up and respawns it when it exits.
- `device/etc/upstart/tailscale.conf` runs `tailscaled` in userspace mode with
  an HTTP proxy on `localhost:1056` and a SOCKS5 proxy on `localhost:1055`. It
  pins the WireGuard port to 41641 and accepts it on `wlan0`, because the stock
  firewall drops unsolicited UDP and otherwise forces DERP.
- `device/etc/upstart/firewall.conf` drops SSH and calibre's wireless port on
  `wlan0`. SSH is reachable over the tailnet only.
- `device/src/blanketd.c` stands in for the removed `com.lab126.blanket` LIPC
  service. `powerd` reads blanket's `load` property before acting on the power
  button and treats an error as "boot splash still showing", so without it the
  device never sleeps. `scripts/build.sh` cross-compiles it with Zig into
  `device/usr/local/bin/`, which `install.sh` expects to exist;
  `device/etc/upstart/blanketd.conf` runs it.
- `install.sh` also changes `early_progress.conf` to stop when `koreader`
  starts. Its stock stop event comes from `langpicker`, which is removed, and
  the boot progress bar would otherwise keep drawing over KOReader.
- `scripts/k.sh` opens an SSH session to the Kindle. `KINDLE_HOST` defaults to
  its tailnet address and `KINDLE_KEY` to `kindle_key` in the repo root.
- `scripts/push-books.sh` copies files into `/mnt/us/documents/inbox` (or the
  directory given with `-d`) over that session.
- `upstart-graph.txt` lists the `start on` and `stop on` conditions of every
  stock upstart job on 5.12.2.2, which is what the drop list was derived from.

## What stays from the stock system

The kernel and its modules (`mxc_epdc_fb` for the display, `cyttsp4` for
touch, `ath6kl_sdio` for Wi-Fi, `g_file_storage` for USB), the boot chain up
to the `lab126` job, and the daemons KOReader talks to over LIPC: `powerd`,
`deviced`, `wifid`, `cmd`, `lipcd` and `volumd`. The squashfs loopbacks are
left mounted because `modules` waits for the event their job emits.

## USB

USB is charge-only. The stock drive mode belonged to the framework: `volumd`
does nothing on its own when a host connects, and `powerd` emits
`usbConfigured` on connect but no event on unplug. Books arrive over the
tailnet instead.

## Library

KOReader's proxy setting points at `http://localhost:1056`, so its OPDS client
reaches calibre-web on the homelab over the tailnet
(`http://homelab:8083/opds`). Calibre's wireless device connection does not
work through that proxy.

## Not in git

`backup/` holds gzipped images of `mmcblk0p1` (rootfs), `mmcblk0p2` and
`mmcblk0p3` taken before `install.sh` ran, with an `MD5SUMS` of the raw
partitions. `backup-2026-11-08/` is a copy of the user store from before any
changes. `dl/` holds the firmware and the third-party packages, `books/` the
library copy, and `kindle_key` the SSH key. Tailscale's node state lives on
the device under `/mnt/us/tailscale/state`.
