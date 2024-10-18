#!/bin/bash

# Define global functions
# This function applies Dell's default dynamic fan control profile
function apply_Dell_fan_control_profile () {
  # Use ipmitool to send the raw command to set fan control to Dell default
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0x30 0x01 0x01 > /dev/null
  CURRENT_FAN_CONTROL_PROFILE="Dell default dynamic fan control profile"
}

# This function applies a user PID fan control profile
function apply_user_fan_control_up () {
  local CURRENT_SPEED=$CURRENT_FAN_SPEED
if ((CPU1_TEMPERATURE > 50))
  then 
    ((CURRENT_SPEED += 15))
    else
    ((CURRENT_SPEED += 10))
fi
  local HEX_SPEED=$(printf '0x%02x' $CURRENT_SPEED )
  # Use ipmitool to send the raw command to set fan control to user-specified value
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0x30 0x01 0x00 > /dev/null
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0x30 0x02 0xff $HEX_SPEED > /dev/null
  CURRENT_FAN_CONTROL_PROFILE="User static fan control profile ($CURRENT_SPEED%)"
  CURRENT_FAN_SPEED=$CURRENT_SPEED
}

function apply_user_fan_control_down () {
  local CURRENT_SPEED=$CURRENT_FAN_SPEED
  if ((CPU1_TEMPERATURE < 42))
  then 
    ((CURRENT_SPEED -= 5))
  else
    ((CURRENT_SPEED--))
  fi

  if ((CURRENT_SPEED < 1))
  then
  CURRENT_SPEED=1
  fi
  local HEX_SPEED=$(printf '0x%02x' $CURRENT_SPEED )
  # Use ipmitool to send the raw command to set fan control to user-specified value
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0x30 0x01 0x00 > /dev/null
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0x30 0x02 0xff $HEX_SPEED > /dev/null
  CURRENT_FAN_CONTROL_PROFILE="User static fan control profile ($CURRENT_SPEED%)"
  CURRENT_FAN_SPEED=$CURRENT_SPEED
}

# Convert first parameter given ($DECIMAL_NUMBER) to hexadecimal
# Usage : convert_decimal_value_to_hexadecimal $DECIMAL_NUMBER
# Returns : hexadecimal value of DECIMAL_NUMBER
function convert_decimal_value_to_hexadecimal () {
  local DECIMAL_NUMBER=$1
  local HEXADECIMAL_NUMBER=$(printf '0x%02x' $DECIMAL_NUMBER)
  echo $HEXADECIMAL_NUMBER
}

# Retrieve temperature sensors data using ipmitool
# Usage : retrieve_temperatures $IS_EXHAUST_TEMPERATURE_SENSOR_PRESENT $IS_CPU2_TEMPERATURE_SENSOR_PRESENT
function retrieve_temperatures () {
  if (( $# != 2 ))
  then
    printf "Illegal number of parameters.\nUsage: retrieve_temperatures \$IS_EXHAUST_TEMPERATURE_SENSOR_PRESENT \$IS_CPU2_TEMPERATURE_SENSOR_PRESENT" >&2
    return 1
  fi
  local IS_EXHAUST_TEMPERATURE_SENSOR_PRESENT=$1
  local IS_CPU2_TEMPERATURE_SENSOR_PRESENT=$2

  local DATA=$(ipmitool -I $IDRAC_LOGIN_STRING sdr type temperature | grep degrees)

  # Parse CPU data
  local CPU_DATA=$(echo "$DATA" | grep "3\." | grep -Po '\d{2}')
  CPU1_TEMPERATURE=$(echo $CPU_DATA | awk '{print $1;}')
  if $IS_CPU2_TEMPERATURE_SENSOR_PRESENT
  then
    CPU2_TEMPERATURE=$(echo $CPU_DATA | awk '{print $2;}')
  else
    CPU2_TEMPERATURE="-"
  fi

  # Parse inlet temperature data
  INLET_TEMPERATURE=$(echo "$DATA" | grep Inlet | grep -Po '\d{2}' | tail -1)

  # If exhaust temperature sensor is present, parse its temperature data
  if $IS_EXHAUST_TEMPERATURE_SENSOR_PRESENT
  then
    EXHAUST_TEMPERATURE=$(echo "$DATA" | grep Exhaust | grep -Po '\d{2}' | tail -1)
  else
    EXHAUST_TEMPERATURE="-"
  fi
}

function enable_third_party_PCIe_card_Dell_default_cooling_response () {
  # We could check the current cooling response before applying but it's not very useful so let's skip the test and apply directly
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0xce 0x00 0x16 0x05 0x00 0x00 0x00 0x05 0x00 0x00 0x00 0x00 > /dev/null
}

function disable_third_party_PCIe_card_Dell_default_cooling_response () {
  # We could check the current cooling response before applying but it's not very useful so let's skip the test and apply directly
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0xce 0x00 0x16 0x05 0x00 0x00 0x00 0x05 0x00 0x01 0x00 0x00 > /dev/null
}

# Returns :
# - 0 if third-party PCIe card Dell default cooling response is currently DISABLED
# - 1 if third-party PCIe card Dell default cooling response is currently ENABLED
# - 2 if the current status returned by ipmitool command output is unexpected
# function is_third_party_PCIe_card_Dell_default_cooling_response_disabled() {
#   THIRD_PARTY_PCIE_CARD_COOLING_RESPONSE=$(ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0xce 0x01 0x16 0x05 0x00 0x00 0x00)

#   if [ "$THIRD_PARTY_PCIE_CARD_COOLING_RESPONSE" == "16 05 00 00 00 05 00 01 00 00" ]; then
#     return 0
#   elif [ "$THIRD_PARTY_PCIE_CARD_COOLING_RESPONSE" == "16 05 00 00 00 05 00 00 00 00" ]; then
#     return 1
#   else
#     echo "Unexpected output: $THIRD_PARTY_PCIE_CARD_COOLING_RESPONSE" >&2
#     return 2
#   fi
# }

# Prepare traps in case of container exit
function gracefull_exit () {
  apply_Dell_fan_control_profile
  enable_third_party_PCIe_card_Dell_default_cooling_response
  echo "/!\ WARNING /!\ Container stopped, Dell default dynamic fan control profile applied for safety."
  exit 0
}

# Helps debugging when people are posting their output
function get_Dell_server_model () {
  IPMI_FRU_content=$(ipmitool -I $IDRAC_LOGIN_STRING fru 2>/dev/null) # FRU stands for "Field Replaceable Unit"
  
  SERVER_MANUFACTURER=$(echo "$IPMI_FRU_content" | grep "Product Manufacturer" | awk -F ': ' '{print $2}')
  SERVER_MODEL=$(echo "$IPMI_FRU_content" | grep "Product Name" | awk -F ': ' '{print $2}')

  # Check if SERVER_MANUFACTURER is empty, if yes, assign value based on "Board Mfg"
  if [ -z "$SERVER_MANUFACTURER" ]; then
    SERVER_MANUFACTURER=$(echo "$IPMI_FRU_content" | tr -s ' ' | grep "Board Mfg :" | awk -F ': ' '{print $2}')
  fi

  # Check if SERVER_MODEL is empty, if yes, assign value based on "Board Product"
  if [ -z "$SERVER_MODEL" ]; then
    SERVER_MODEL=$(echo "$IPMI_FRU_content" | tr -s ' ' | grep "Board Product :" | awk -F ': ' '{print $2}')
  fi
}
# Define global functions
# This function applies Dell's default dynamic fan control profile
function apply_Dell_fan_control_profile () {
  # Use ipmitool to send the raw command to set fan control to Dell default
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0x30 0x01 0x01 > /dev/null
  CURRENT_FAN_CONTROL_PROFILE="Dell default dynamic fan control profile"
}

# This function applies a user PID fan control profile
function apply_user_fan_control_up () {
  local CURRENT_SPEED=$CURRENT_FAN_SPEED
if ((CPU1_TEMPERATURE > 50))
  then 
    ((CURRENT_SPEED += 15))
    else
    ((CURRENT_SPEED += 10))
fi
  local HEX_SPEED=$(printf '0x%02x' $CURRENT_SPEED )
  # Use ipmitool to send the raw command to set fan control to user-specified value
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0x30 0x01 0x00 > /dev/null
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0x30 0x02 0xff $HEX_SPEED > /dev/null
  CURRENT_FAN_CONTROL_PROFILE="User static fan control profile ($CURRENT_SPEED%)"
  CURRENT_FAN_SPEED=$CURRENT_SPEED
}

function apply_user_fan_control_down () {
  local CURRENT_SPEED=$CURRENT_FAN_SPEED
  if ((CPU1_TEMPERATURE < 42))
  then 
    ((CURRENT_SPEED -= 5))
  else
    ((CURRENT_SPEED--))
  fi

  if ((CURRENT_SPEED < 1))
  then
  CURRENT_SPEED=1
  fi
  local HEX_SPEED=$(printf '0x%02x' $CURRENT_SPEED )
  # Use ipmitool to send the raw command to set fan control to user-specified value
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0x30 0x01 0x00 > /dev/null
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0x30 0x02 0xff $HEX_SPEED > /dev/null
  CURRENT_FAN_CONTROL_PROFILE="User static fan control profile ($CURRENT_SPEED%)"
  CURRENT_FAN_SPEED=$CURRENT_SPEED
}

# Convert first parameter given ($DECIMAL_NUMBER) to hexadecimal
# Usage : convert_decimal_value_to_hexadecimal $DECIMAL_NUMBER
# Returns : hexadecimal value of DECIMAL_NUMBER
function convert_decimal_value_to_hexadecimal () {
  local DECIMAL_NUMBER=$1
  local HEXADECIMAL_NUMBER=$(printf '0x%02x' $DECIMAL_NUMBER)
  echo $HEXADECIMAL_NUMBER
}

# Retrieve temperature sensors data using ipmitool
# Usage : retrieve_temperatures $IS_EXHAUST_TEMPERATURE_SENSOR_PRESENT $IS_CPU2_TEMPERATURE_SENSOR_PRESENT
function retrieve_temperatures () {
  if (( $# != 2 ))
  then
    printf "Illegal number of parameters.\nUsage: retrieve_temperatures \$IS_EXHAUST_TEMPERATURE_SENSOR_PRESENT \$IS_CPU2_TEMPERATURE_SENSOR_PRESENT" >&2
    return 1
  fi
  local IS_EXHAUST_TEMPERATURE_SENSOR_PRESENT=$1
  local IS_CPU2_TEMPERATURE_SENSOR_PRESENT=$2

  local DATA=$(ipmitool -I $IDRAC_LOGIN_STRING sdr type temperature | grep degrees)

  # Parse CPU data
  local CPU_DATA=$(echo "$DATA" | grep "3\." | grep -Po '\d{2}')
  CPU1_TEMPERATURE=$(echo $CPU_DATA | awk '{print $1;}')
  if $IS_CPU2_TEMPERATURE_SENSOR_PRESENT
  then
    CPU2_TEMPERATURE=$(echo $CPU_DATA | awk '{print $2;}')
  else
    CPU2_TEMPERATURE="-"
  fi

  # Parse inlet temperature data
  INLET_TEMPERATURE=$(echo "$DATA" | grep Inlet | grep -Po '\d{2}' | tail -1)

  # If exhaust temperature sensor is present, parse its temperature data
  if $IS_EXHAUST_TEMPERATURE_SENSOR_PRESENT
  then
    EXHAUST_TEMPERATURE=$(echo "$DATA" | grep Exhaust | grep -Po '\d{2}' | tail -1)
  else
    EXHAUST_TEMPERATURE="-"
  fi
}

function enable_third_party_PCIe_card_Dell_default_cooling_response () {
  # We could check the current cooling response before applying but it's not very useful so let's skip the test and apply directly
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0xce 0x00 0x16 0x05 0x00 0x00 0x00 0x05 0x00 0x00 0x00 0x00 > /dev/null
}

function disable_third_party_PCIe_card_Dell_default_cooling_response () {
  # We could check the current cooling response before applying but it's not very useful so let's skip the test and apply directly
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0xce 0x00 0x16 0x05 0x00 0x00 0x00 0x05 0x00 0x01 0x00 0x00 > /dev/null
}

# Returns :
# - 0 if third-party PCIe card Dell default cooling response is currently DISABLED
# - 1 if third-party PCIe card Dell default cooling response is currently ENABLED
# - 2 if the current status returned by ipmitool command output is unexpected
# function is_third_party_PCIe_card_Dell_default_cooling_response_disabled() {
#   THIRD_PARTY_PCIE_CARD_COOLING_RESPONSE=$(ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0xce 0x01 0x16 0x05 0x00 0x00 0x00)

#   if [ "$THIRD_PARTY_PCIE_CARD_COOLING_RESPONSE" == "16 05 00 00 00 05 00 01 00 00" ]; then
#     return 0
#   elif [ "$THIRD_PARTY_PCIE_CARD_COOLING_RESPONSE" == "16 05 00 00 00 05 00 00 00 00" ]; then
#     return 1
#   else
#     echo "Unexpected output: $THIRD_PARTY_PCIE_CARD_COOLING_RESPONSE" >&2
#     return 2
#   fi
# }

# Prepare traps in case of container exit
function gracefull_exit () {
  apply_Dell_fan_control_profile
  enable_third_party_PCIe_card_Dell_default_cooling_response
  echo "/!\ WARNING /!\ Container stopped, Dell default dynamic fan control profile applied for safety."
  exit 0
}

# Helps debugging when people are posting their output
function get_Dell_server_model () {
  IPMI_FRU_content=$(ipmitool -I $IDRAC_LOGIN_STRING fru 2>/dev/null) # FRU stands for "Field Replaceable Unit"
  
  SERVER_MANUFACTURER=$(echo "$IPMI_FRU_content" | grep "Product Manufacturer" | awk -F ': ' '{print $2}')
  SERVER_MODEL=$(echo "$IPMI_FRU_content" | grep "Product Name" | awk -F ': ' '{print $2}')

  # Check if SERVER_MANUFACTURER is empty, if yes, assign value based on "Board Mfg"
  if [ -z "$SERVER_MANUFACTURER" ]; then
    SERVER_MANUFACTURER=$(echo "$IPMI_FRU_content" | tr -s ' ' | grep "Board Mfg :" | awk -F ': ' '{print $2}')
  fi

  # Check if SERVER_MODEL is empty, if yes, assign value based on "Board Product"
  if [ -z "$SERVER_MODEL" ]; then
    SERVER_MODEL=$(echo "$IPMI_FRU_content" | tr -s ' ' | grep "Board Product :" | awk -F ': ' '{print $2}')
  fi
}


# Trap the signals for container exit and run gracefull_exit function
trap 'gracefull_exit' SIGQUIT SIGKILL SIGTERM

# Prepare, format and define initial variables
IDRAC_HOST=<iDrac IP>
IDRAC_USERNAME=root
IDRAC_PASSWORD=<Password>
FAN_SPEED=1
CPU_TEMPERATURE_THRESHOLD=48
CHECK_INTERVAL=30
DISABLE_THIRD_PARTY_PCIE_CARD_DELL_DEFAULT_COOLING_RESPONSE=false


# Define the interval for printing


readonly TABLE_HEADER_PRINT_INTERVAL=10
# Set the flag used to check if the active fan control profile has changed
IS_DELL_FAN_CONTROL_PROFILE_APPLIED=true
# Check present sensors
IS_EXHAUST_TEMPERATURE_SENSOR_PRESENT=true
IS_CPU2_TEMPERATURE_SENSOR_PRESENT=true
readonly COOL_TEMP=$((CPU_TEMPERATURE_THRESHOLD - 3))
readonly SUPER_COOL_TEMP=$((CPU_TEMPERATURE_THRESHOLD - 6))
readonly SUPER_HOT_TEMP=$((CPU_TEMPERATURE_THRESHOLD + 3))

# Check if FAN_SPEED variable is in hexadecimal format. If not, convert it to hexadecimal
if [[ $FAN_SPEED == 0x* ]]
then
    DECIMAL_FAN_SPEED=$(printf '%d' $FAN_SPEED)
else
    DECIMAL_FAN_SPEED=$FAN_SPEED
fi
# init the current fan speed
CURRENT_FAN_SPEED=$((DECIMAL_FAN_SPEED + 10))


# Check if the iDRAC host is set to 'local' or not then set the IDRAC_LOGIN_STRING accordingly
  #echo "iDRAC/IPMI username: $IDRAC_USERNAME" >> /home/idrac/log.txt
  #echo "iDRAC/IPMI password: $IDRAC_PASSWORD" >> /home/idrac/log.txt
  IDRAC_LOGIN_STRING="lanplus -H $IDRAC_HOST -U $IDRAC_USERNAME -P $IDRAC_PASSWORD"


get_Dell_server_model

if [[ ! $SERVER_MANUFACTURER == "DELL" ]]
then
  echo "/!\ Your server isn't a Dell product. Exiting."  >> /home/idrac/log.txt
  exit 1
fi

# Log main informations
echo "Server model: $SERVER_MANUFACTURER $SERVER_MODEL" >> /home/idrac/log.txt
echo "iDRAC/IPMI host: $IDRAC_HOST" >> /home/idrac/log.txt

# Log the fan speed objective, CPU temperature threshold and check interval
echo "Fan speed objective: $DECIMAL_FAN_SPEED%"  >> /home/idrac/log.txt
echo "CPU temperature threshold: $CPU_TEMPERATURE_THRESHOLD°C" >> /home/idrac/log.txt
echo "Check interval: ${CHECK_INTERVAL}s" >> /home/idrac/log.txt
echo "Current fan speed: ${CURRENT_FAN_SPEED}" >> /home/idrac/log.txt
echo "" >> /home/idrac/log.txt

i=$TABLE_HEADER_PRINT_INTERVAL

retrieve_temperatures $IS_EXHAUST_TEMPERATURE_SENSOR_PRESENT $IS_CPU2_TEMPERATURE_SENSOR_PRESENT
if [ -z "$EXHAUST_TEMPERATURE" ]
then
  echo "No exhaust temperature sensor detected." >> /home/idrac/log.txt
  IS_EXHAUST_TEMPERATURE_SENSOR_PRESENT=false
fi
if [ -z "$CPU2_TEMPERATURE" ]
then
  echo "No CPU2 temperature sensor detected." >> /home/idrac/log.txt
  IS_CPU2_TEMPERATURE_SENSOR_PRESENT=false
fi
# Output new line to beautify output if one of the previous conditions have echoed
if ! $IS_EXHAUST_TEMPERATURE_SENSOR_PRESENT || ! $IS_CPU2_TEMPERATURE_SENSOR_PRESENT
then
  echo "" >> /home/idrac/log.txt
fi

# Start monitoring
while true; do
  # Sleep for the specified interval before taking another reading
  sleep $CHECK_INTERVAL &
  SLEEP_PROCESS_PID=$!

  retrieve_temperatures $IS_EXHAUST_TEMPERATURE_SENSOR_PRESENT $IS_CPU2_TEMPERATURE_SENSOR_PRESENT

  # Define functions to check if CPU 1 and CPU 2 temperatures are above the threshold
  function CPU1_OVERHEAT () { [ $CPU1_TEMPERATURE -gt $CPU_TEMPERATURE_THRESHOLD ]; }
  if $IS_CPU2_TEMPERATURE_SENSOR_PRESENT
  then
    function CPU2_OVERHEAT () { [ $CPU2_TEMPERATURE -gt $CPU_TEMPERATURE_THRESHOLD ]; }
  fi

   function CPU1_COOL () { [ $CPU1_TEMPERATURE -lt $COOL_TEMP ]; }
  if $IS_CPU2_TEMPERATURE_SENSOR_PRESENT
  then
    function CPU2_COOL () { [ $CPU2_TEMPERATURE -lt $COOL_TEMP ]; }
  fi


  # Initialize a variable to store the comments displayed when the fan control profile changed
  COMMENT=" -"


    # Check if CPU(s) overheating then apply Dell default dynamic fan control profile if true
    if CPU1_OVERHEAT || ($IS_CPU2_TEMPERATURE_SENSOR_PRESENT && CPU2_OVERHEAT)
    then

        #echo "CPU(s) temperature is too high, increasing fan speed,Current fan speed: ${CURRENT_FAN_SPEED}" >> /home/idrac/log.txt
        if [ $CURRENT_FAN_SPEED -lt 30 ] &&  ((CPU1_TEMPERATURE < SUPER_HOT_TEMP)) &&  ((CPU1_TEMPERATURE < 55))
        then
            apply_user_fan_control_up
            COMMENT="CPU(s) temperature is high, increasing fan speed"
            IS_DELL_FAN_CONTROL_PROFILE_APPLIED=false
        else
            apply_Dell_fan_control_profile
            COMMENT="CPU(s) temperature is too high, Dell default dynamic fan control profile applied for safety"
            CURRENT_FAN_SPEED=16
            # Check if user fan control profile is applied then apply it if not
            IS_DELL_FAN_CONTROL_PROFILE_APPLIED=true
        fi
    else
        #echo "CPU(s) temperature is under control, decreasing fan speed,Current fan speed: ${CURRENT_FAN_SPEED}" >> /home/idrac/log.txt
        # Check if CPU(s) cold, lower the fan speed
        if $IS_CPU2_TEMPERATURE_SENSOR_PRESENT
        then
            if CPU1_COOL && CPU2_COOL
            then
                if [ $CURRENT_FAN_SPEED -gt $DECIMAL_FAN_SPEED ]
                then
                    apply_user_fan_control_down
                    COMMENT="CPUs temperature is cool, lowering fan speed"
                    IS_DELL_FAN_CONTROL_PROFILE_APPLIED=false
                fi
            fi
        else
            if CPU1_COOL
            then
                if [ $CURRENT_FAN_SPEED -gt $DECIMAL_FAN_SPEED ]
                then
                    apply_user_fan_control_down
                    COMMENT="CPU 1 temperature is cool, lowering fan speed"
                    IS_DELL_FAN_CONTROL_PROFILE_APPLIED=false
                fi
            fi
        fi
    
    fi

 #echo "Target fan speed: ${DECIMAL_FAN_SPEED},Cool Temp: ${COOL_TEMP},Current fan speed: ${CURRENT_FAN_SPEED}" >> /home/idrac/log.txt
       

  # Enable or disable, depending on the user's choice, third-party PCIe card Dell default cooling response
  # No comment will be displayed on the change of this parameter since it is not related to the temperature of any device (CPU, GPU, etc...) but only to the settings made by the user when launching this Docker container
  if $DISABLE_THIRD_PARTY_PCIE_CARD_DELL_DEFAULT_COOLING_RESPONSE
  then
    disable_third_party_PCIe_card_Dell_default_cooling_response
    THIRD_PARTY_PCIE_CARD_DELL_DEFAULT_COOLING_RESPONSE_STATUS="Disabled"
  else
    enable_third_party_PCIe_card_Dell_default_cooling_response
    THIRD_PARTY_PCIE_CARD_DELL_DEFAULT_COOLING_RESPONSE_STATUS="Enabled"
  fi

  # Print temperatures, active fan control profile and comment if any change happened during last time interval
  if [ $i -eq $TABLE_HEADER_PRINT_INTERVAL ]
  then
    echo "                     ------- Temperatures -------" >> /home/idrac/log.txt
    echo "    Date & time      Inlet  CPU 1  CPU 2  Exhaust          Active fan speed profile          Third-party PCIe card Dell default cooling response  Comment" >> /home/idrac/log.txt
    i=0
  fi
    printf "%19s  %3d°C  %3d°C  %3s°C  %5s°C  %40s  %51s  %s\n" "$(date +"%d-%m-%Y %T")" $INLET_TEMPERATURE $CPU1_TEMPERATURE "$CPU2_TEMPERATURE" "$EXHAUST_TEMPERATURE" "$CURRENT_FAN_CONTROL_PROFILE" "$THIRD_PARTY_PCIE_CARD_DELL_DEFAULT_COOLING_RESPONSE_STATUS" "$COMMENT" >> /home/idrac/log.txt
    ((i++))
    wait $SLEEP_PROCESS_PID
done
