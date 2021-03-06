#!/bin/bash
# wolfgang.ztoeg@web.de 20130915

syno_hostname="diskstation"
syno_photo="/volume1/photo"
syno_mount_photo="/net/$syno_hostname$syno_photo"

declare -A Findex
declare -A Dindex

mkdir="mkdir"
convert="convert"
ssh="ssh"


function reduce {
	for d in "${!Dindex[@]}";do
		if [ ${Dindex[$d]} -eq 1 ];then
			if [ "$d" != "$syno_mount_photo" ];then
				Dindex["${d%/*}"]=2
			fi
		fi
	done
	
	for d in "${!Dindex[@]}";do
		if [ ${Dindex["$d"]}0 -eq 20 ];then
			flag=1
			D=($(find $d -mindepth 1 -maxdepth 1 -type d ! -name "@eaDir" -printf "%f\n"))
			for r in "${D[@]}";do
				if [ ${Dindex["$d/$r"]}0 -ne 10 ];then
					flag=0
				fi
			done
			if [ $flag -eq 1 ];then
				Dindex["$d"]=1
				for r in "${D[@]}";do
					 unset Dindex["$d/$r"]
				done
			fi
		fi
	done
}


function atexit {
	echo -n "index "

	for f in "${!Findex[@]}";do
		[ ${Dindex[${f%/*}]}0 -eq 0 ] && { $ssh admin@$syno_hostname "synoindex -a \"${f/$syno_mount_photo/$syno_photo}\""; echo -n a; }
	done

	rold=-1 
	until [ $rold -eq ${#Dindex[@]} ];do
		rold=${#Dindex[@]}
		reduce
	done
	
	for d in "${!Dindex[@]}";do
		if [ ${Dindex[$d]}  -eq 1 ];then
			$ssh admin@$syno_hostname "/usr/syno/bin/synoindex -R \"${d/$syno_mount_photo/$syno_photo}\""
			echo INDEX ${d/$syno_mount_photo/$syno_photo}
		fi
	done

	echo
	echo photostation+mediaserver ok, wait for background indexer to finish
	echo

}



timeout -k 10 5 ssh admin@$syno_hostname uptime
[ $? -eq 0 ] || { echo ssh failed; exit 1; }

[ -d "$syno_mount_photo" ] || { echo no mount, 1minute for autofs; exit 1; }

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
	[ -d "$e" ] || { Findex[$f]=1; $mkdir "$e"; F=1; }
	if [ "$f" -nt  "$x" ] ; then
		echo -n "$f"
		$convert -resize 1280x1280 "$f" "$x"; echo -n " X"
		$convert -resize 640x640   "$x" "$b"; echo -n " B"
		$convert -resize 320x320   "$b" "$m"; echo -n " M"
		$convert -resize 120x120   "$m" "$s"; echo -n " S"
		if [ $F -eq 1 ]; then
			echo " IDX"
		else
			echo 
		fi
	fi
done < <(find $syno_mount_photo/ -path "*/@eaDir" -prune -o -type f -print)

