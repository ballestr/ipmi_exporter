#!/bin/bash
## readout of IPMI sensors via local interface
## originally for Ganglia, Sergio Ballestrero 2014-01-11
## repurposed for Prometheus, Sergio Ballestrero 2018

MAPFILE=/etc/node_exporter.d/ipmisensors.map
OPT+=" -Q --sdr-cache-recreate --workaround=ignorescanningdisabled"
## restrict to some sensors
OPT+=" -t Temperature,Voltage,Current,Fan "

## no support for SCRAPE_INTERVAL on this, see comment at end

function readout_sensors {
ipmi-sensors $OPT --comma-separated-output --ignore-not-available-sensors --entity-sensor-names --no-header-output | while IFS=',' read -r id name class value unit state ; do
  if [[ $value == "N/A" ]]; then
    case $state in 
    "'OK'") value=0;;
    "'Presence detected'") value=1;;
    "'Entity Present'") value=1;;
    "'Entity Absent'") value=1;;
    "'Cable/Interconnect is connected'") value=1;;
    "'Processor Presence detected'") value=1;;
    "'Drive Presence'") value=1;;
    "'battery presence detected'") value=1;;
    "'Fully Redundant'") value=1;;
    "'State Deasserted'") value=0;;
    *)    value=-99;;
    esac
  fi
  [[ $value == -99 ]] && [[ -t 1 ]] && echo "$id : $name : $class : $value : $unit : $state"
  [[ ${sensorlabel[$id]} ]] && label=",label=\"${sensorlabel[$id]}\"" || label=""
  case $class in
  Voltage|Temperature|Current|Fan) 
    type=$(echo $class|tr " /[A-Z]" "__[a-z]")
    [[ $unit == 'N/A' ]] && type+="_state"
    ;;
  Cable/Interconnect|Memory|"Entity Presence") 
    type="state";label+=",class=\"$class\"";;
  *)
    type="other";label+=",class=\"$class\"";;
  esac
  [[ $unit != 'N/A' ]] && unit=",unit=\"$unit\"" || unit=""
  metric=$(printf 'node_ipmisensor_%s{id="%s",hw="%s",name="%s"%s%s} %s' $type "$id" "$hw" "$name" "$unit" "$label" "$value")
  echo $metric
done
}

## check if we have freeipmi
[ -x /usr/sbin/ipmi-sensors ] || exit 1


hwmanufacturer=$(facter manufacturer|awk '{print $1}')
hwproduct=$(facter productname|tr ' ' _)
hw="${hwmanufacturer}_${hwproduct}"

declare -a sensorlabel
for line in $(egrep -v "^#" $MAPFILE); do
  IFS=':' read id label <<< $line
  #echo "$id label=$label"
  sensorlabel[$id]="$label"
done

while true; do
  (
  ## the +1 is the "create set" line, so a 0 would mean the setname does not exist
  echo "# HELP node_ipmisensor_X various sensors readout from ipmi_exportall"
  echo "# TYPE node_ipmisensor_X gauge"
  readout_sensors
  ) | sponge /var/lib/prometheus/ipmisensors.prom

  ## ABSOLUTELY DO NOT POLL TOO OFTEN
  ## you're guaranteed to run into problems if your BMC is too busy
  sleep 60
done
