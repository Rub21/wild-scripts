# !/usr/bin/env bash
outputDir=data
rm -rf $outputDir
mkdir -p $outputDir

wget http://download.geofabrik.de/africa-latest.osm.pbf -O $outputDir/osm.pbf 

# Creating poly file for clip the pbf file
docker run --rm -v ${PWD}:/mnt/data developmentseed/geokit:latest geokit bbox2fc \
--bbox="30.410426936943182,5.487766360430384,39.418930263056815,18.520923057982287" >  $outputDir/nile-bbox.geojson
docker run --rm -v ${PWD}:/mnt/data developmentseed/geokit:latest geojson2poly \
$outputDir/nile-bbox.geojson $outputDir/bounduary.poly

# Clip the pbf file for the area
docker run --rm -v ${PWD}:/mnt/data developmentseed/geokit:latest osmconvert \
$outputDir/osm.pbf  -B=$outputDir/bounduary.poly -o=$outputDir/osm-clip.pbf

# converting pbf -> osm
docker run --rm -v ${PWD}:/mnt/data developmentseed/geokit:latest osmosis \
--read-pbf file=$outputDir/osm-clip.pbf --write-xml $outputDir/osm.osm

# Filter Pole and comunication tower
docker run --rm -v ${PWD}:/mnt/data developmentseed/geokit:latest osmfilter $outputDir/osm.osm \
--keep="tower=pole or 
        man_made=communications_tower or 
        tower:type=communication" > $outputDir/tower.osm

# converting osm -> geojson
docker run --rm -v ${PWD}:/mnt/data developmentseed/geokit:latest osmtogeojson \
$outputDir/tower.osm> $outputDir/tower.geojson

# Cover point to Polygon, 20 meters distances
docker run --rm -v ${PWD}:/mnt/data developmentseed/geokit:latest geokit fc2square \
$outputDir/tower.geojson --radius=20 \
> $outputDir/tower-squares.geojson

# flatten
geojson-flatten $outputDir/tower-squares.geojson > $outputDir/nile_osm_towers_bbox.geojson

