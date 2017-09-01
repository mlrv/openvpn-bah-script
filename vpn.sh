#!/bin/bash

#Initialise script variables
SCRIPT=`basename ${BASH_SOURCE[0]}`
ALLFILES=(./openvpn/*)
RANDOMSERVER=
COUNTRY=""
ALLNAMES=()

#Initialise ANSI escape codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

#Function to print usage/ help message
function usage() {
  echo -e "${SCRIPT} - Connect to a VPN server"
  echo -e \\n"Usage: ${SCRIPT} [options]"\\n
  echo "Options: "
  echo "-r  <random>     Pick a random server"
  echo "-c  <country>    Pick a server in a specific country"
  echo "-l  <locations>  List available locations"
  echo ""
  exit 1
}

#Function to get available locations
function getPossibleLocations() {
  for FILE in ${ALLFILES[@]}
    do 
      ALLNAMES+=(${FILE:10:2})
    done  
  ALLNAMES=( `for i in ${ALLNAMES[@]}; do echo $i; done | sort -u` )
}

#Function to print available locations
function printPossibleLocations() {
  echo -e "Available locations:"\\n
  echo -e ${GREEN}[${NC} ${ALLNAMES[@]} ${GREEN}]${NC}\\n
  echo -e "Example: bash vpn.sh -c ca"
}

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -r|--random)
      RANDOMSERVER="true"
      shift 
    ;;
    -c|--country)
      COUNTRY="$2"
      shift 
    ;;
    -l|--locations)
      GETLOCATION="true"
      getPossibleLocations
      printPossibleLocations
    ;;
    -h|--help)
    usage
    ;;
    *)
      echo -e \\n"${RED}Invalid option $key specified${NC}"\\n
      usage
    ;;
esac
shift # past argument or value
done

#Check for dependencies
OPENVPN=`which openvpn`
if [ "$OPENVPN" == "" ]; then
   echo "${RED}Error: Missing dependencies${NC}"
   exit 1
fi

#Check for mandatory options
if [ -z "$COUNTRY" ] && [ "$GETLOCATION" != "true" ] && [ "$RANDOMSERVER" != "true" ]; then
  echo -e "${RED}Error: You need to select one of the options${NC}"\\n && usage
fi

set -e

if [ "$RANDOMSERVER" == "true" ]; then
  getPossibleLocations
  OPTIONS=(./openvpn/*)
  echo "Choosing random server...(${#OPTIONS[@]} options)"
  openvpn ${OPTIONS[RANDOM % ${#OPTIONS[@]}]}
fi

if [ "$COUNTRY" != "" ]; then
  getPossibleLocations
  OPTIONS=(./openvpn/${COUNTRY}*)

  #Check that ${COUNTRY} exists in the list
  if printf '%s\0' "${ALLNAMES[@]}" | grep -Fqxz ${COUNTRY}
    then
      echo "Choosing server from $COUNTRY... (${#OPTIONS[@]} options)"
      openvpn ${OPTIONS[RANDOM % ${#OPTIONS[@]}]}
  
    else 
      echo -e "${RED}Error: $COUNTRY is not an available country${NC}"\\n
      printPossibleLocations
  fi
fi