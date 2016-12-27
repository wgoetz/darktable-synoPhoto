#!/bin/bash
# wolfgang.ztoeg@web.de 20161227

dt_cache=$(ls -d ~/.cache/darktable/mipmaps-*.d)
mip_stage=4
album="$HOME/Pictures/dt-mip/$mip_stage"

darktable-generate-cache -m $mip_stage 

while IFS="|" read n i d f;do
	[[ "$d" =~ [[:digit:]] ]] || continue

	nb=${n%%.*}
	if="$dt_cache/$mip_stage/$i.jpg"
	IFS=":" read Y M r <<< "$d"
	fb=${f##*/}

	od="$album/$Y/$M/$fb" 
	of="$od/$nb.jpg"
	
	[ -d "$od" ] || mkdir -pv "$od" 
	[ -f "$of" ] || { cp -p $if "$of"; echo -n .; } 
done < <(sqlite3 ~/.config/darktable/library.db "select filename,images.id,datetime_taken,film_rolls.folder from images inner join film_rolls on images.film_id=film_rolls.id;")

