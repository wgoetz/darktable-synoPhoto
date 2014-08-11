#!/bin/bash
# wolfgang.ztoeg@web.de
#

dt_cli="/opt/darktable/bin/darktable-cli"

IFS="," read xmp out <<< $1

t="/tmp/${out##*/}"
raw=${xmp%.xmp}

echo -n "$out "

[ -f "$t" ] && rm -v "$t"
mtime=$(/usr/bin/stat --format="%y" "$xmp")
outfmt=$(identify -format "--width %W --height %H" "$out")
cat "$raw" > /dev/null

flock /var/lock/dt-cli.lock /usr/bin/time -a -o /tmp/dt-cli.time -f "%E %C"\
	$dt_cli "$raw" "$t" $outfmt\
    	--core -d opencl 2>/dev/null|grep summary

/usr/bin/touch --date="$mtime" "$xmp"
[ -s "$t" ] && mv  "$t" "$out"

