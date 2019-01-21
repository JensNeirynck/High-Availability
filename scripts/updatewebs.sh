#!/bin/bash

# Script voor de rolling updates uit te voeren
# Author:
#	Jens Neirynck

# Special thanks to the teachers @HoGent for the support!

# Colors
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ORANGE='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'		 #No Color

file="$1"
path="$2"
echo $file
AANTALSERVERS="$(grep -r "Aantal webservers" webservers.conf | awk '{print $3}')"

echo "aantal:"
echo $AANTALSERVERS

for (( i=1;i<=$AANTALSERVERS; i++ ))	
do
scp $file root@192.168.1.$((i+4)):$2
done