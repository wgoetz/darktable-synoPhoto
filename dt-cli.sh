#!/bin/bash
# wolfgang.ztoeg@web.de
#

dt_cli="/opt/darktable/bin/darktable-cli"

IFS="," read xmp out <<< $1

t="/tmp/${out##*/}"
raw=${xmp%/*}/$(exiftool -s -S -f -DerivedFrom $xmp)

[ -f $raw ] || { echo "NOT FOUND: $raw" ; exit 1; }

echo -n "$out "

a=$(exiftool -s -S -f -History_params "$xmp")
b=$(exiftool -s -S -f -History_params "$out")
mtime=$(/usr/bin/stat --format="%y" "$xmp")

if [ "$a" = "$b" ];then
	/usr/bin/touch --date="$mtime" "$out"
	echo "touched due to no picture content change"
else
	[ -f "$t" ] && rm -v "$t"
	outfmt=$(identify -format "--width %W --height %H" "$out")
	cat "$raw" > /dev/null

	flock /var/lock/dt-cli.lock /usr/bin/time -a -o /tmp/dt-cli.time -f "%E %C"\
		$dt_cli "$raw" "$t" $outfmt\
    		--core -d opencl 2>/dev/null|grep summary

	/usr/bin/touch --date="$mtime" "$xmp"
	[ -s "$t" ] && mv  "$t" "$out"
fi
