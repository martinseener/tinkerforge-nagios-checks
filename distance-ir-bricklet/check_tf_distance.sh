#!/usr/bin/env bash

# check_tf_distance.sh v1.0
# (c) 2013 - Martin Seener (martin@seener.de)

# This Nagios check will connect to your tinkerforge distance-ir-bricklet, read the measured distance
# and alert you when the distance is more or less than a given distance using a treshold.
# The treshold can be calculated using tf_distance_ir_bricklet_stddev_calc.sh script. For that built up
# your bricklet with the distance you want to measure and run that script for one or two hours (3600 or 7200)
# measurements. It will calculate the standard deviation for you which then can be used as the treshold.

# This check can be used for example for a distance check, if a door in a server rack was opened, therefore
# the distance between the bricklet and the door has de- or increased.

PROGNAME=$(basename $0)
VERSION="Version 1.0,"
AUTHOR="2013, Martin Seener (martin@seener.de)"

# Nagios States
STATE_OK=0
STATE_WARN=1
STATE_CRIT=2
STATE_UNKNOWN=3

print_version() {
  echo "$VERSION $AUTHOR"
}

print_help() {
  print_version $PROGNAME $VERSION
  echo ""
  echo "$PROGNAME is a Nagios plugin to check the distance measured by a tinkerforge distance-ir-bricklet."
  echo "This check requires the Brick Daemon 'brickd' to be installed as well as the tinkerforge api shell bindings."
  echo "You can find them here: http://www.tinkerforge.com/de/doc/index.html#software"
  echo ""
  echo "Usage: $0 <bricklet_uid> <desired_distance_in_mm> <measurement_treshold_in_mm> | $0 hDu 1000 5"
  echo ""
}

check_prerequisites() {
  TINKERFORGE=$(which tinkerforge)
  if [ "$?" -ne 0 ]; then
    echo "Unable to find the tinkerforge shell bindings. Please install them first and dont miss brickd."
    echo ""
    print_help
    exit $STATE_UNKNOWN
  fi
  $TINKERFORGE enumerate | grep $1 > /dev/null 2>&1
  if [ "$?" -ne 0 ]; then
    echo "Unable to find the distance-ir-bricklet with the UID: $1"
    echo ""
    print_help
    exit $STATE_UNKNOWN
  fi
}

initialize() {
  if [ -z "$1" ]; then
    echo "Sorry, but the first argument is missing, and has to be the UID of the distance-ir-bricklet!"
    echo ""
    print_help
    exit $STATE_UNKNOWN
  fi
  if [[ ! $2 =~ ^[0-9]+$ ]] || [ $2 -eq 0 ]; then
    echo "Sorry, but the second argument must be a positiver integer starting at 1 or higher!"
    echo ""
    print_help
    exit $STATE_UNKNOWN
  fi
  if [[ ! $3 =~ ^[0-9]+$ ]] || [ $2 -eq 0 ]; then
    echo "Sorry, but the second argument must be a positiver integer starting at 1 or higher!"
    echo ""
    print_help
    exit $STATE_UNKNOWN
  fi

  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
}

measure_distance() {
  DISTANCE=$($TINKERFORGE call distance-ir-bricklet $1 get-distance | cut -d'=' -f2)

  # Calculate minimum distance
  MIN_DESIRED=$(echo "scale=0; ($2 - $3)/1" | bc)
  MAX_DESIRED=$(echo "scale=0; ($2 + $3)/1" | bc)
  if [[ $DISTANCE -ge $MIN_DESIRED ]] && [[ $DISTANCE -le $MAX_DESIRED ]]; then
    echo "OK - Measured: $DISTANCE mm, Expected: $2 mm, Treshold: $3 mm|measured=$DISTANCE,expected=$2,treshold=$3"
    exit $STATE_OK
  fi

  # Measured distance is not in the range, so we check the doubled standard deviation
  MIN_DESIRED2=$(echo "scale=0; ($2 - (2 * $3))/1" | bc)
  MAX_DESIRED2=$(echo "scale=0; ($2 + (2 * $3))/1" | bc)
  if [[ $DISTANCE -ge $MIN_DESIRED2 ]] && [[ $DISTANCE -le $MAX_DESIRED2 ]]; then
    echo "WARNING - Measured: $DISTANCE mm, Expected: $2 mm, Treshold: $3 mm|measured=$DISTANCE,expected=$2,treshold=$3"
    exit $STATE_WARN
  else
    echo "CRITICAL - Measured: $DISTANCE mm, Expected: $2 mm, Treshold: $3 mm|measured=$DISTANCE,expected=$2,treshold=$3"
    exit $STATE_CRIT
  fi
}

case "$1" in
  --help|-h)
    print_help
    exit $STATE_UNKNOWN
    ;;
  --version|-v)
    print_version $PROGNAME $VERSION
    exit $STATE_UNKNOWN
    ;;
  *)
    ;;
esac

# Initialize the Check
initialize $1 $2 $3
# Check prerequisites
check_prerequisites $1
# Measure the distance
measure_distance $1 $2 $3
