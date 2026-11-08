#!/bin/sh
# Strips the stock Kindle framework from a jailbroken PW2 on 5.12.2.2 and
# installs KOReader as the only UI. Run as root on the device from a copy of
# this directory. Keeps the boot chain, powerd, deviced, wifid, cmd, lipcd,
# volumd, usbnet and dropbear, which KOReader and the kernel drivers need.
set -e
export PATH=/usr/sbin:/sbin:/usr/bin:/bin
cd "$(dirname "$0")"

mount -o remount,rw /
trap 'mount -o remount,ro /' EXIT

# Some stock files carry the immutable attribute.
while read -r j; do
	f="/etc/upstart/$j.conf"
	[ -e "$f" ] || continue
	chattr -i "$f" 2>/dev/null || true
	rm -f "$f"
done < drop-jobs.txt

# The stock fonts (Bookerly and others) are the squashfs image fonts.sqsh,
# mounted on /usr/java/lib/fonts at boot; KOReader reads them from there.
for e in /usr/java/bin /usr/java/lib/*; do
	case "$e" in /usr/java/lib/fonts | /usr/java/lib/fonts.sqsh) continue ;; esac
	rm -rf "$e"
done
while read -r f; do
	[ -e "$f" ] || continue
	chattr -R -i "$f" 2>/dev/null || true
	rm -rf "$f"
done < drop-files.txt
while read -r l; do
	[ -e "$l" ] || [ -L "$l" ] || continue
	chattr -i "$l" 2>/dev/null || true
	rm -f "$l"
done < drop-libs.txt

cp etc/upstart/*.conf /etc/upstart/
cp usr/local/bin/blanketd /usr/local/bin/blanketd
chmod 755 /usr/local/bin/blanketd
rm -f /etc/upstart/evlog.conf /etc/upstart/usbms.conf /usr/local/bin/usbms /usr/local/bin/fbink

# lab126 waits for demd, which only feeds Amazon's device metrics.
sed -i 's/^start on started system_setup_after_shpm and started demd$/start on started system_setup_after_shpm/' /etc/upstart/lab126.conf
# The boot progress bar stops on langpicker, which is gone.
sed -i 's/^stop on starting langpicker *$/stop on starting koreader/' /etc/upstart/early_progress.conf
sed -i -e '/loginfo/d' -e '/dem_heartbeat/d' /etc/crontab/root
grep -q todo-ta-g7g /etc/hosts || cat hosts.block >> /etc/hosts

sync
