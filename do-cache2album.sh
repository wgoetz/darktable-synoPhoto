#!/bin/bash
# wolfgang.ztoeg@web.de 20161227

dt_cache=$(ls -d ~/.cache/darktable/mipmaps-*.d)
mip_stage=4
album="$HOME/Pictures/dt-mip/test2"
declare -i ofn

darktable-generate-cache -m $mip_stage 

while IFS="|" read n i d f;do
	[[ "$d" =~ [[:digit:]] ]] || continue

	nb=${n%%.*}
	if="$dt_cache/$mip_stage/$i.jpg"
	[ -f $if ] || continue

	IFS=":" read Y M r <<< "$d"
	fb=${f##*/}

	od="$album/$Y/$M/$fb" 
	
	[ -d "$od" ] || { mkdir -p "$od"; echo -n M; }
 
	of="$od/$nb.jpg"
	ofn=0
	until cp -pus $if "$of" 2>/dev/null ; do
		if [[ $(readlink "$of") =~ \/$i.jpg ]]; then
			rm "$of"
		else
			ofn+=1
			if [ $ofn -lt 100 ];then
				of=$(printf "$od/${nb}_%02d.jpg" $ofn)
			else 
				of=$(printf "$od/${nb}_%d.jpg" $ofn)
			fi
		fi
	done

done < <(sqlite3 ~/.config/darktable/library.db "select filename,images.id,datetime_taken,film_rolls.folder from images inner join film_rolls on images.film_id=film_rolls.id;")

