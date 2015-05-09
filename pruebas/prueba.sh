#!/bin/bash
function cantidad (){
	cant=$(ls -1 /home/pc/Escritorio/ | wc -l)
	return cant

}

cantidad
echo "x vale $cant"
