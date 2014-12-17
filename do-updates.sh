#!/bin/bash
# wolfgang.ztoeg@web.de 20140203

syno_hostname="diskstation"
syno_photo="/volume1/photo"
syno_mount_photo="/net/$syno_hostname$syno_photo"
dt_xml="/data/digi"

function dtcli {
	dt_cli="darktable-cli"
	IFS="," read xmp out <<< "$1"

	tout="/tmp/${out##*/}"
	raw=${xmp%/*}/$(exiftool -s -S -f -DerivedFrom "$xmp")

	[ -f "$raw" ] || { echo "NOT FOUND: $raw"; exit 1; }

	echo -n "$out "

	d="${out%/*}/@eaDir"
	e="$d/${out##*/}"
	x="$e/SYNOPHOTO_THUMB_XL.jpg"
	b="$e/SYNOPHOTO_THUMB_B.jpg"
	m="$e/SYNOPHOTO_THUMB_M.jpg"
	s="$e/SYNOPHOTO_THUMB_S.jpg"


	aHist=$(exiftool -s -S -f -History_params "$xmp")
	bHist=$(exiftool -s -S -f -History_params "$out")

	if [ "$aHist" = "$bHist" ];then
		touch "$out" "$x" "$b" "$m" "$s"
		echo "touched due to no picture content change"
	else
		[ -f "$tout" ] && rm -v "$tout"
		outfmt=$(identify -format "--width %W --height %H" "$out")
		cat "$raw" > /dev/null
		mtime=$(/usr/bin/stat --format="%y" "$xmp")

		flock /tmp/dt-cli.lock /usr/bin/time -a -o /tmp/dt-cli.time -f "%E %C"\
			$dt_cli "$raw" "$tout" $outfmt\
			--core -d opencl 2>/dev/null|grep summary|tr -d \\n

		/usr/bin/touch --date="$mtime" "$xmp"
		if [ -s "$tout" ];then
			mv  "$tout" "$out"
			convert -resize 1280x1280 "$out" "$x"; echo -n " X"
			convert -resize 640x640   "$x" "$b"; echo -n " B"
			convert -resize 320x320   "$b" "$m"; echo -n " M"
			convert -resize 120x120   "$m" "$s"; echo -n " S"
			echo
		fi
	fi
}
export -f dtcli

declare -A Xindex


timeout 5 ssh admin@$syno_hostname uptime
[ $? -eq 0 ] || { echo ssh failed; exit 1; }

[ -d "$syno_mount_photo" ] || { echo no mount, 1minute for autofs; exit 1; }

while read f;do
	b=${f##*/}
	k=${b%%.*}
	Xindex[$k]=$f
done < <(find $dt_xml -name \*.xmp -print)


while read f;do
	b=${f##*/}
	k=${b%%.*}
	xmp=${Xindex[$k]}
	[ "$xmp" -a  "$xmp" -nt "$f" ] && pargs+=("$xmp,$f")
done < <(find $syno_mount_photo/ -path "*/@eaDir" -prune -o -type f -print)


parallel -j2 dtcli :::: < <(IFS=$'\n'; echo "${pargs[*]}"|grep -v "_01.jpg")

