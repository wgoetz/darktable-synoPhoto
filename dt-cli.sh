#!/bin/bash
# wolfgang.ztoeg@web.de
#

dt_cli="/opt/darktable/bin/darktable-cli"

IFS="," read xmp out <<< $1

t="/tmp/${out##*/}"
nef=${xmp%.xmp}

echo -n "$out "

[ -f "$t" ] && rm -v "$t"
mtime=$(/usr/bin/stat --format="%y" "$xmp")

cat "$nef" > /dev/null
(
	flock -x 9 || exit 1
	/usr/bin/time -a -o /tmp/dt-cli.time -f "%E %C" $dt_cli "$nef" "$t"\
	       	$(identify -format "--width %W --height %H" "$out")\
	       	--core -d opencl 2>/dev/null|grep summary

) 9>/var/lock/dt-cli.lock

/usr/bin/touch --date="$mtime" "$xmp"
[ -s "$t" ] && mv  "$t" "$out"

