# Tinkerforge Nagios Checks

Here you can find a collection of self written nagios checks for the tinkerforge system.
As soon as i have the possibility to get a new brick or bricklet, i will update this repository
with new checks. Feel free to send me some!

## distance-ir-bricklet

The Nagios Tinkerforge Distance IR Bricklet check was built to get the distance the bricklet measures
and compares that value against the minimum desired distance and the maximum desired distance given by
a single desired distance and a treshold. Its provided as the `check_tf_distance.sh` script

The treshold can be calculated for each distance-ir-bricklet itself using the provided `tf_distance_ir_bricklet_stddev_calc.sh`
script. It measures the distance once a second for a user-defined amount of total measurements and calculates the first standard
deviation from it which will then provide the treshold for the nagios check.

For a good standard deviation, built up your bricklet with the desired distance it should measure later and run the script with some thousands of measurements (i recommend 7200 whereas the script will run about 2 hours in that case).

The nagios check itself then uses the standard deviation provided as the treshold to generate warnings if the measurement is larger than the first standard deviation and a critical if its more than the second standard deviation or twice the treshold.

### How to get the standard deviation/check treshold?

1. Built up your test case with the desired distance you want to measure
2. Run the tf_distance_ir_bricklet_stddev_calc.sh script to get measurements and to calculate the standard deviation
    - `bash tf_distance_ir_bricklet_stddev_calc.sh <distance_ir_bricklet_UID> <sample_points>`
    - `bash tf_distance_ir_bricklet_stddev_calc.sh hVu 7200`
3. The script will output the standard deviation which is the treshold for the check itself

### How to use the check?

1. Obviously you should know how to use nagios checks and this one works the same. Just an example.
    - `check_tf_distance.sh <bricklet_uid> <desired_distance_in_mm> <measurement_treshold_in_mm>`
    - in action: `check_tf_distance.sh hVu 1000 12`

### How does a Nagios message look like?

#### Critical State

```
--SERVICE-ALERT-------------------
-
- Hostaddress: 10.0.0.1
- Hostname:    monitor.example.com
- Service:     Check Rack Door Distance: monitor.example.com
- - - - - - - - - - - - - - - - -
- State:       CRITICAL
- Date:        2013-11-06 18:30:14
- Output:      CRITICAL - Measured: 1438 mm, Expected: 1010 mm, Treshold: 5 mm
-
----------------------------------
```

#### Normal State

```
--SERVICE-ALERT-------------------
-
- Hostaddress: 10.0.0.1
- Hostname:    monitor.example.com
- Service:     Check Rack Door Distance: monitor.example.com
- - - - - - - - - - - - - - - - -
- State:       OK
- Date:        2013-11-06 18:34:50
- Output:      OK - Measured: 1010 mm, Expected: 1010 mm, Treshold: 5 mm
-
----------------------------------
```

## Copyright and License

(c) 2013 Martin Seener

Released under the GNU GPLv2