#!/bin/bash
# wolfgang.ztoeg@web.de 20130915

syno_hostname="diskstation"
syno_mount="diskstation"


declare -A Findex

mkdir="mkdir"
convert="convert"
ssh="ssh"

ssh admin@$syno_hostname uptime

[ -d "/$syno_mount/photo" ] || { echo no mount; exit 1; }

while read f;do
	e="${f%/*}/@eaDir/${f##*/}"
	x="$e/SYNOPHOTO_THUMB_XL.jpg"
	b="$e/SYNOPHOTO_THUMB_B.jpg"
	m="$e/SYNOPHOTO_THUMB_M.jpg"
	s="$e/SYNOPHOTO_THUMB_S.jpg"
	F=0
	[ -d "$e" ] || { $mkdir -p "$e"; F=1; Findex[$f]=1; echo -n "$f"; }
	[ -f "$x" ] || { $convert -resize 1280x1280 "$f" "$x"; echo -n " X"; }
	[ -f "$b" ] || { $convert -resize 640x640   "$x" "$b"; echo -n " B"; }
	[ -f "$m" ] || { $convert -resize 320x320   "$b" "$m"; echo -n " M"; }
	[ -f "$s" ] || { $convert -resize 120x120   "$m" "$s"; echo -n " S"; }
	[ $F -eq 1 ] && { echo "."; }
done < <(find /$syno_mount/photo -path "*/@eaDir" -prune -o -type f -print)


for f in "${!Findex[@]}";do
	$ssh admin@$syno_hostname "synoindex -a ${f/$syno_mount/volume1}"
	echo -n .
done
