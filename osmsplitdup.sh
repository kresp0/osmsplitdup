#!/bin/bash

# Split nodes in a osm file that are near a node in another osm file
# Two files are created:
# file-to-remove-duplicates-dup.osm
#     and
# file-to-remove-duplicates-not_dup.osm

# Tags to add to each node
TAGS="<tag k='amenity' v='bicycle_parking' />"
# Max. distance to consider a duplicate in meters
MAX_DISTANCE=25

TMPDIR=/tmp/osmsplitdup
BASENAME=`echo $2 | awk -F '.' '{print $1}'`
EARTH_RADIUS="6371"
PI="3.141592653589793"

if [[ $# -eq 0 ]] ; then
    echo 'Usage: ./Use: ./osmsplitdup.sh file-with-OSM-data.osm file-to-remove-duplicates.osm'
    echo 'You have to edit the TAGS and MAX_DISTANCE variables'
    exit 0
fi

rm -rf $TMPDIR
mkdir -p $TMPDIR

# To use a RAM disk
#sudo mount -t tmpfs -o size=1G osmsplitdup-ramdisk $TMPDIR

function addNode {                   
   echo "
  <node id='$1' action='modify' visible='true' lat='$2' lon='$3'>
$TAGS
  </node>" >> $4

} 

function deg2rad {
        bc -l <<< "$1 * $PI / 180"
}

function rad2deg  {
        bc -l <<< "$1 * 180 / $PI"
}

function acos  {
        bc -l <<<"$PI / 2 - a($1 / sqrt(1 - $1 * $1))"
}

function getDistance {
    LAT1=$1
    LONG1=$2
    LAT2=$3
    LON2=$4
    
	delta_lat=$(bc <<<"$LAT2 - $LAT1")
	delta_lon=$(bc <<<"$LON2 - $LONG1")
	LAT1=$(deg2rad "$LAT1")
	LONG1=$(deg2rad "$LONG1")
	LAT2=$(deg2rad "$LAT2")
	LON2=$(deg2rad "$LON2")
	delta_lat=$(deg2rad "$delta_lat")
	delta_lon=$(deg2rad "$delta_lon")

	DISTANCE=$(bc -l <<< "s($LAT1) * s($LAT2) + c($LAT1) * c($LAT2) * c($delta_lon)")

	DISTANCE=$(acos "$DISTANCE")
	DISTANCE=$(bc -l <<< "$DISTANCE * $EARTH_RADIUS")
	DISTANCE=$(bc <<<"$DISTANCE * 1000")
#    DISTANCE=$(printf "%.3f" $DISTANCE)
	DISTANCE=`echo "scale=3;$DISTANCE/1" | bc`
	echo $DISTANCE
}

grep 'node id' $1 | awk -F "lat=" '{print $2}' | awk -F "'" '{print $2";"$4}' | grep -v '0\.00000' | sort -nu > $TMPDIR/osm-data
grep 'node id' $2 | awk -F "lat=" '{print $2}' | awk -F "'" '{print $2";"$4}' | grep -v '0\.00000' | sort -nu > $TMPDIR/data-to-split

echo "<?xml version='1.0' encoding='UTF-8'?>
<osm version='0.6' upload='false' generator='osmsplitdup.sh'>" > $BASENAME-dup.osm

echo "<?xml version='1.0' encoding='UTF-8'?>
<osm version='0.6' upload='false' generator='osmsplitdup.sh'>" > $BASENAME-not_dup.osm

COUNT=0
COUNTDUP=0
COUNTNOTDUP=0

cp $TMPDIR/osm-data $TMPDIR/to-compare

while IFS='' read -r line || [[ -n "$line" ]]; do
   let COUNT=COUNT-1

   LAT_SPLIT=`echo "$line" | awk -F ";"  '{print $1}'`
   LON_SPLIT=`echo "$line" | awk -F ";"  '{print $2}'`
   DUP=0
   echo "Testing $LAT_SPLIT $LON_SPLIT"

   while IFS='' read -r line2 || [[ -n "$line2" ]]; do
      LAT_NODE=`echo "$line2" | awk -F ";"  '{print $1}'`
      LON_NODE=`echo "$line2" | awk -F ";"  '{print $2}'`
      DISTANCE_NODE=`getDistance $LAT_SPLIT $LON_SPLIT $LAT_NODE $LON_NODE`
      DISTANCE_IS_LESS_THAN_MAX=`echo $DISTANCE_NODE'<'$MAX_DISTANCE | bc -l`
      
      if [ $DISTANCE_IS_LESS_THAN_MAX -eq 1 ];then
         addNode $COUNT $LAT_SPLIT $LON_SPLIT $BASENAME-dup.osm
	     echo "DUP: $COUNT $LAT_SPLIT $LON_SPLIT is $DISTANCE_NODE meters away from $LAT_NODE $LON_NODE"
         let COUNTDUP=COUNTDUP+1
#         grep -v "$LAT_NODE;$LON_NODE" $TMPDIR/to-compare > /tmp/foo ; mv /tmp/foo $TMPDIR/to-compare # Puede haber varios to-split cerca de un to-compare
         DUP=1
         break
      fi

   done < $TMPDIR/to-compare

   if [ $DUP -eq 0 ];then
   addNode $COUNT $LAT_SPLIT $LON_SPLIT $BASENAME-not_dup.osm
   let COUNTNOTDUP=COUNTNOTDUP+1    
   echo "NOT DUP: $COUNT $LAT_SPLIT $LON_SPLIT"
   fi


done < $TMPDIR/data-to-split

echo "</osm>" >> $BASENAME-dup.osm
echo "</osm>" >> $BASENAME-not_dup.osm


echo "DUP: $COUNTDUP"
echo "NOT DUP: $COUNTNOTDUP"
