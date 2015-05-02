#!/bin/bash
#tab defaults
#correr con ambiente ya inicializado
#mae y 	tab creados

dirnovedades="$GRUPO$NOVEDIR/"

dir=$(pwd)
cd "$GRUPO$BINDIR"
./Start.sh RecPro.sh
cd $dir
#exit 1
OKfiles=("Alfonsin_RES_1001_388_23-05-1989" "Fernandez2_DIS_1010_33_04-01-2015" "Fernandez2_RES_1001_413_30-04-2015" "Kirchner_DEC_2121_9042_27-6-2007" "Duhalde_RES_1001_294_23-05-2003" "Fernandez2_DIS_1010_55_30-01-2015" "Fernandez_CON_2002_7_05-03-2010" "Fernandez2_CON_4444_11_04-05-2015" "Fernandez2_DIS_1010_66_07-02-2015" "Fernandez_CON_6006_7_11-12-2009" "Saa_RES_1001_963_28-12-2001" "Fernandez2_DIS_1010_100_03-05-2015" "Fernandez2_DIS_3737_86_30-03-2015" "Fernandez_DIS_1010_7590_02-12-2011" "Fernandez2_DIS_1010_101_07-05-2015" "Fernandez2_DIS_6006_22_28-04-2015" "Kirchner_DAD_2222_72_28-06-2007" )
for file in ${OKfiles[@]}; do
        touch "$dirnovedades$file" 
done

sleep 5

### CASOS BASE
aprotoc="$GRUPO$ACEPDIR/"
sol="0"
for aFile in ${OKfiles[@]}; do
        name=$(echo "$aFile" | cut -d"_" -f1)
        file="$aprotoc$name/$aFile"
        if [ -f "$file" ]; then
        	echo "EXISTEEE $file"
        	rm $file
        else
        	sol="1"
        	echo "ERROR no Existe $file"
        fi
done

if [ "$sol" -eq "0" ]; then
	echo "OK en casos base"
else
	echo "ERROR en casos base"
fi


dir=$(pwd)
cd "$GRUPO$BINDIR"
./Stop.sh RecPro.sh
cd $dir
