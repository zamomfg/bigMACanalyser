#!/bin/bash

MACs=$1
macfile=macs.txt

macUrl="https://standards-oui.ieee.org/"
SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

macParser(){

MAC=$1

# MAC=$(echo $MAC | tr -d ':' | tr -d '-' | tr '[:lower:]' '[:upper:]')

OUIMAC=${MAC:0:6}

macInfo=$(cat $macfile | grep -i "\b$OUIMAC\b" -A 3)
readarray -t arr <<<"$macInfo"

company=$(echo ${arr[0]} | cut -d ")" -f2 | tr -d '\r' | cut -c 2-) 
address1=$(echo ${arr[1]} | tr -d '\t' | tr -d '\r')
address2=$(echo ${arr[2]} | tr -d '\t' | tr -d '\r')
addressCountry=$(echo ${arr[3]} | tr -d '\t' | tr -d '\r')


firstHex=${MAC:0:1}
binary=$(echo "obase=2; ibase=16; $firstHex" | bc)

ulBit=${binary: -2:1}
# bc dont output leading zeros so i need to set the mit manualy if firstHex is 1 or 0
if [ "$ulBit" = "" -o "$ulBit" = "0" ]; then
    ulBit="MULTICAST"
else
    ulBit="UNICAST"
fi

igBit=${binary: -1}
if [ "$igBit" = "" -o "$igBit" = "0" ]; then
    igBit="Universally Administered"
else
    igBit="Locally Administered"
fi

if [ "$MAC" = "FFFFFFFFFFFF" ]; then
    company="BROADCAST"
    addressCountry="N/A"
fi

if [ "$company" = "Private" ]; then
    address1="N/A"
    address2="N/A"
    addressCountry="N/A"
fi

filler="************"
MAC=$(printf '%s\n' "$MAC${filler:${#MAC}}")

MAC=$(echo $MAC | sed -r 's/.{2}/&-/g')
MAC=${MAC::-1}

printOut "$MAC" "$company" "$ulBit" "$igBit" "$addressCountry"

}

printOut(){
    printf "%-30s %-30s %-30s %-30s %-30s %-30s\n" "$1" "$2" "$3" "$4" "$5"
}

main(){
    MACs=$(echo $MACs | tr "," " ")
MACs=($MACs)

printOut "MAC-Address" "Organization (OUI)" "Individual/Group" "Administration" "Org Country"

pattern="^[0-9A-F]{6,12}$"
for MAC in "${MACs[@]}"
do

    MAC=$(echo $MAC | tr -d ':' | tr -d '-' | tr '[:lower:]' '[:upper:]')
    if [[ $MAC =~ $pattern ]]; then
        macParser $MAC
    else
        printOut "$MAC" "Invalid Address" "Invalid Address" "Invalid Address" "Invalid Address"
    fi

done
}

echo $SCRIPT $SCRIPTPATH
if [ -f "$SCRIPTPATH/$macfile" ]; then
    main
else
    echo "MAC-Address lookup file where not found"
    echo
    echo "Do you want to download the file from $macUrl? Y/n"
    read input
    if [ "${input^^}" = "Y" ] || [ "$input" = "" ]; then
        echo "Dowloading file. Please wait"
        wget $macUrl -O "$SCRIPTPATH/$macfile" -q --show-progress
        main
    elif [ "${input^^}" = "N" ]; then
        echo "Closing program"
        exit 0
    else
        echo "ERROR: input Y or N expected"
    fi
fi