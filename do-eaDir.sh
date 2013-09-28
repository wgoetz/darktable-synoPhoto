#!/bin/bash
# wolfgang.ztoeg@web.de 20130915

syno_hostname="diskstation"
syno_mount="diskstation"

declare -A Findex
declare -A Dindex

mkdir="mkdir"
convert="convert"
ssh="ssh"


function atexit {
	echo -n "index "

	for f in "${!Findex[@]}";do
		[ ${Dindex[${f%/*}]}0 -eq 0 ] && { $ssh admin@$syno_hostname "synoindex -a ${f/$syno_mount/volume1}"; echo -n a; }
	done

	for d in "${!Dindex[@]}";do
		$ssh admin@$syno_hostname "synoindex -R ${d/$syno_mount/volume1}"
		echo -n R		
	done

	echo
	echo photostation+mediaserver ok, wait for background indexer to finish
	echo

}



timeout 2 ssh admin@$syno_hostname uptime
[ $? -eq 0 ] || { echo ssh failed; exit 1; }

[ -d "/$syno_mount/photo" ] || { echo no mount, 1minute for autofs; exit 1; }

trap atexit EXIT

while read f;do
	d="${f%/*}/@eaDir"
	e="$d/${f##*/}"
	x="$e/SYNOPHOTO_THUMB_XL.jpg"
	b="$e/SYNOPHOTO_THUMB_B.jpg"
	m="$e/SYNOPHOTO_THUMB_M.jpg"
	s="$e/SYNOPHOTO_THUMB_S.jpg"
	F=0
	[ -d "$d" ] || { Dindex[${f%/*}]=1; $mkdir "$d"; }
	[ -d "$e" ] || { Findex[$f]=1; $mkdir "$e"; F=1; echo -n "$f"; }
	[ -f "$x" ] || { $convert -resize 1280x1280 "$f" "$x"; echo -n " X"; }
	[ -f "$b" ] || { $convert -resize 640x640   "$x" "$b"; echo -n " B"; }
	[ -f "$m" ] || { $convert -resize 320x320   "$b" "$m"; echo -n " M"; }
	[ -f "$s" ] || { $convert -resize 120x120   "$m" "$s"; echo -n " S"; }
	[ $F -eq 1 ] && { echo "."; }
done < <(find /$syno_mount/photo -path "*/@eaDir" -prune -o -type f -print)

