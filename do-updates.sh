#!/bin/bash
# wolfgang.ztoeg@web.de 20140203

syno_hostname="diskstation"
syno_mount="diskstation"
dt_xml="/data/digi"
dt_cli="/opt/darktable/bin/darktable-cli"

declare -A Xindex
F=0


timeout 5 ssh admin@$syno_hostname uptime
[ $? -eq 0 ] || { echo ssh failed; exit 1; }

[ -d "/$syno_mount/photo" ] || { echo no mount, 1minute for autofs; exit 1; }

while read f;do
	b=${f##*/}
	k=${b%%.*}
	Xindex[$k]=$f
done < <(find $dt_xml -name \*.xmp -print)


while read f;do
	b=${f##*/}
	k=${b%%.*}
	t="/tmp/$b"

	if [ "${Xindex[$k]}" -a  "${Xindex[$k]}" -nt "$f" ];then
		[ -f "$t" ] && rm -v "$t"
		echo $dt_cli "${Xindex[$k]%.xmp}" "$t" $(identify -format "--width %W --height %H" "$f")
		echo mv "$t" "$f"
		F=1
	fi
done < <(find /$syno_mount/photo -path "*/@eaDir" -prune -o -type f -print)


if [ $F -eq 1 ];then
	do-eaDir.sh
fi

