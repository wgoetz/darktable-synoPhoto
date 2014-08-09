#!/bin/bash
# wolfgang.ztoeg@web.de
#

dt_cli="/opt/darktable/bin/darktable-cli"

IFS="," read xmp out <<< $1

t="/tmp/${out##*/}"

echo -n "$out "

[ -f "$t" ] && rm -v "$t"
mtime=$(/usr/bin/stat --format="%y" "$xmp")
/usr/bin/time -a -o /tmp/dt-cli.time -f "%E %C" $dt_cli "${xmp%.xmp}" "$t" $(identify -format "--width %W --height %H" "$out") --core -d opencl 2>/dev/null |grep summary
/usr/bin/touch --date="$mtime" "$xmp"
[ -f "$t" ] && mv  "$t" "$out"

