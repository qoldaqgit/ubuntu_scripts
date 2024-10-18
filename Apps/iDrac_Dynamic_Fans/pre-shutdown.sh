#!/bin/bash
IDRAC_HOST=<iDrac IP>
IDRAC_USERNAME=root
IDRAC_PASSWORD=<Password>

IDRAC_LOGIN_STRING="lanplus -H $IDRAC_HOST -U $IDRAC_USERNAME -P $IDRAC_PASSWORD"
# Define global functions
# This function applies Dell's default dynamic fan control profile
function apply_Dell_fan_control_profile () {
  # Use ipmitool to send the raw command to set fan control to Dell default
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0x30 0x01 0x01 > /dev/null
  CURRENT_FAN_CONTROL_PROFILE="Dell default dynamic fan control profile"
}
function enable_third_party_PCIe_card_Dell_default_cooling_response () {
  # We could check the current cooling response before applying but it's not very useful so let's skip the test and apply directly
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0xce 0x00 0x16 0x05 0x00 0x00 0x00 0x05 0x00 0x00 0x00 0x00 > /dev/null
}


  apply_Dell_fan_control_profile
  enable_third_party_PCIe_card_Dell_default_cooling_response
  echo "/!\ WARNING /!\ Container stopped/!\ WARNING /!\ " >> /home/idrac/log.txt
  exit 0
#!/bin/bash
IDRAC_HOST=10.10.10.18
IDRAC_USERNAME=root
IDRAC_PASSWORD=Thor+Hulk=$

IDRAC_LOGIN_STRING="lanplus -H $IDRAC_HOST -U $IDRAC_USERNAME -P $IDRAC_PASSWORD"
# Define global functions
# This function applies Dell's default dynamic fan control profile
function apply_Dell_fan_control_profile () {
  # Use ipmitool to send the raw command to set fan control to Dell default
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0x30 0x01 0x01 > /dev/null
  CURRENT_FAN_CONTROL_PROFILE="Dell default dynamic fan control profile"
}
function enable_third_party_PCIe_card_Dell_default_cooling_response () {
  # We could check the current cooling response before applying but it's not very useful so let's skip the test and apply directly
  ipmitool -I $IDRAC_LOGIN_STRING raw 0x30 0xce 0x00 0x16 0x05 0x00 0x00 0x00 0x05 0x00 0x00 0x00 0x00 > /dev/null
}


  apply_Dell_fan_control_profile
  enable_third_party_PCIe_card_Dell_default_cooling_response
  echo "/!\ WARNING /!\ Container stopped/!\ WARNING /!\ " >> /home/idrac/log.txt
  exit 0
