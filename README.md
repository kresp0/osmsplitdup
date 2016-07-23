# osmsplitdup.sh
Split nodes in a osm file that are near a node in another osm file

Two files are created:
file-to-remove-duplicates-dup.osm
   and
file-to-remove-duplicates-not_dup.osm

You have to edit the TAGS and MAX_DISTANCE variables

Usage: ./osmboxes.sh file-with-OSM-data.osm file-to-remove-duplicates.osm

