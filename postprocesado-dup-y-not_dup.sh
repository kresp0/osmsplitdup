#!/bin/bash

BASENAME=`ls -1 *-not_dup.osm | awk -F '-not_dup' '{print $1}'`

perl -pe 's/\n//g' $BASENAME.osm | perl -pe 's/<\/node>/<\/node>\n/g' | perl -pe "s/generator='JOSM'>/generator='JOSM'>\n/g" > 1 ; mv 1 $BASENAME.osm

grep 'action=' *-not_dup.osm > not_dup
grep 'action=' *-dup.osm > dup

echo "<?xml version='1.0' encoding='UTF-8'?>
<osm version='0.6' upload='false' generator='postprocesado-dup-y-not_dup.sh'>" > $BASENAME-no-duplicados.osm
cp $BASENAME-no-duplicados.osm $BASENAME-duplicados.osm

while IFS= read -r line
do
  LAT=`echo $line | awk -F "lat" '{print $2}' | awk -F "'" '{print $2}' | awk -F '.' '{print $2}'`
  LON=`echo $line | awk -F "lon" '{print $2}' | awk -F "'" '{print $2}' | awk -F '.' '{print $2}'`
  grep $LAT $BASENAME.osm | grep "$LON" >> $BASENAME-no-duplicados.osm
done < not_dup

while IFS= read -r line
do
  LAT=`echo $line | awk -F "lat" '{print $2}' | awk -F "'" '{print $2}' | awk -F '.' '{print $2}'`
  LON=`echo $line | awk -F "lon" '{print $2}' | awk -F "'" '{print $2}' | awk -F '.' '{print $2}'`
  grep $LAT $BASENAME.osm | grep "$LON" >> $BASENAME-duplicados.osm
done < dup

echo "</osm>" >> $BASENAME-no-duplicados.osm
echo "</osm>" >> $BASENAME-duplicados.osm

#rm dup not_dup *dup.osm
