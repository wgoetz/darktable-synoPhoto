#!/bin/bash
# wolfgang.ztoeg@web.de
#

dt_cli="/opt/darktable/bin/darktable-cli"

IFS="," read xmp out <<< $1

t="/tmp/${out##*/}"
raw=${xmp%.xmp}  # assuming ONE sidecar file: beware of dt duplicates: TODO:look into xmp and remove q&d filter in calling script

echo -n "$out "


a=$(xpath -q -s "" -e x:xmpmeta/rdf:RDF/rdf:Description/darktable:history_params/rdf:Seq/rdf:li "$xmp"|sed 's/<[^>]*>//g;a \'|sha1sum|cut -b-40)
b=$(exiftool -s -S -f -History_params "$out"|sed 's/, //g'|sha1sum|cut -b-40)
mtime=$(/usr/bin/stat --format="%y" "$xmp")

if [ $a = $b ];then
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
