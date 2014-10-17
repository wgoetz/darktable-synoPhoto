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
	xmp=${Xindex[$k]}

	if [ "$xmp" -a  "$xmp" -nt "$f" ];then
		pargs+=("$xmp,$f")
		F=1
	fi
done < <(find /$syno_mount/photo/ -path "*/@eaDir" -prune -o -type f -print)


parallel --sshlogin 2/: dt-cli.sh :::: < <(IFS=$'\n'; echo "${pargs[*]}"|grep -v "_01.jpg")

