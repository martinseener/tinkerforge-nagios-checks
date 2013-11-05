#!/usr/bin/env bash

# tf-distance-ir-bricklet-stddev-calc.sh
# v1.0 (c) 2013, Martin Seener (martin@seener.de)

# Calculates the standard deviation of the distance-ir-bricklet
# by measuring a user-defined time in seconds whereas every second a sample is recorded
# to a sample_file for later use.

PROGNAME=`basename $0`
VERSION="Version 1.0,"
AUTHOR="2013, Martin Seener (martin@seener.de)"

print_version() {
  echo "$VERSION $AUTHOR"
}

print_help() {
  print_version $PROGNAME $VERSION
  echo ""
  echo "$PROGNAME is a tool to calculate the standard deviation of tinkerforge's distance-ir-bricklet to be used for the nagios distance-check as the treshold."
  echo "This tool requires the Brick Daemon 'brickd' to be installed as well as the tinkerforge api shell bindings."
  echo "You can find them here: http://www.tinkerforge.com/de/doc/index.html#software"
  echo ""
  echo "Usage: $0 <bricklet_uid> <desired_sample_points> | $0 hDu 120"
  echo "The example would measure 120 sample points (about one each second) and calculate the standard deviation out of it."
  echo ""
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

### FUNCTIONS

check_prerequisites() {
  TINKERFORGE=$(which tinkerforge)
  if [ "$?" -ne 0 ]; then
    echo "Unable to find the tinkerforge shell bindings. Please install them first and dont miss brickd."
    echo ""
    print_help
    exit 3
  fi
  $TINKERFORGE enumerate | grep $1 > /dev/null 2>&1
  if [ "$?" -ne 0 ]; then
    echo "Unable to find the distance-ir-bricklet with the UID: $1"
    echo ""
    print_help
    exit 3
  fi
}

measure_samples() {
  touch $3 > /dev/null 2>&1
  if [ "$?" -ne 0 ]; then
    echo "Unable to create the local sample file: ./$SAMPLEFILE. Maybe i dont have write permissions?"
    echo ""
    print_help
    exit 3
  fi
  for ((i=$2; i>0; i--))
  do
    $TINKERFORGE call distance-ir-bricklet $1 get-distance | cut -d'=' -f2 >> $3
    sleep 1
  done
}

arithmetic_mean () {
  local RT=0         # Running total
  local AM=0         # Arithmetic mean
  local SCT=0        # Sample Point count
  while read VALUE
  do
    RT=$(echo "scale=$SCALE; $RT + $VALUE" | bc)
    (( SCT++ ))
  done < $1
  AM=$(echo "scale=$SCALE; $RT / $SCT" | bc)
  echo "$AM#$SCT"
}

standard_deviation() {
  ARITHMEAN=$(arithmetic_mean $1)

  MEAN1=$(echo $ARITHMEAN | cut -d'#' -f1)  # Arithmetic mean
  MEAN2=$(echo $ARITHMEAN | cut -d'#' -f2)  # Sample Point count
  SUM2=0                                    # Sum of squared differences ("variance").
  AVG2=0                                    # Average of $sum2.
  STDDEV=0                                  # Standard Deviation.

  while read VALUE
  do
    DIFF=$(echo "scale=$SCALE; $MEAN1 - $VALUE" | bc)
    DIFF2=$(echo "scale=$SCALE; $DIFF * $DIFF" | bc)
    SUM2=$(echo "scale=$SCALE; $SUM2 + $DIFF2" | bc)
  done < $1

  AVG2=$(echo "scale=$SCALE; $SUM2 / $MEAN2" | bc)
  STDDEV=$(echo "scale=$SCALE; sqrt($AVG2)" | bc)
  echo $STDDEV
}

initialize() {
  if [ -z "$1" ]; then
    echo "Sorry, but the first argument is missing, and has to be the UID of the distance-ir-bricklet!"
    echo ""
    print_help
    exit 3
  fi
  if [[ ! $2 =~ ^[0-9]+$ ]] || [ $2 -eq 0 ]; then
    echo "Sorry, but the second argument must be a positiver integer starting at 1 or higher!"
    echo ""
    print_help
    exit 3
  fi

  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  SAMPLEFILE="distance_ir_samples_$TIMESTAMP.dat"
  BRICKLETUID=$1
  SAMPLEPOINTS=$2
  SCALE=9      # Scale used by bc. Default 9 decimal places
}

### START

# Initialize with parameter-check and creation of the timestamp and sample file
initialize $1 $2
# Check if there is a distance-ir-bricklet there with the specified uid
check_prerequisites $BRICKLETUID
# Measure the samples
measure_samples $BRICKLETUID $SAMPLEPOINTS $SAMPLEFILE
# Calculate the standard deviation
echo "The standard deviation for the sample points in: $SAMPLEFILE is $(standard_deviation $SAMPLEFILE)"

# We are done
exit 0