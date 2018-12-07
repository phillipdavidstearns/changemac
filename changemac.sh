#!/bin/bash

#--------------------------------------------------------------------
#	A simple bash script to make changing/spoofing your MAC address
#	easier on your OSX 10.13+ system. Inspired by macchanger.
#	Yes, I'm reinventing the wheel in a very kludgy way.
#
#	Written by Phillip David Stearns 2018.
#
#   Was written for OSX 10.13
#   Dependencies: networksetup, airport, openssl
#--------------------------------------------------------------------

#a helpful usage message

function usage {
  echo -e "\nUsage: changemac [-hcprRv] [interface] [MAC]"
  echo -e "NOTE: Must be run as root!\n"
  echo -e "\t-h\t\tdisplay this help message"
  echo -e "\t-c\t\tshow current MAC address"
  echo -e "\t-p\t\tshow permanent hardware MAC address"
  echo -e "\t-r\t\trandomize MAC address"
  echo -e "\t-R\t\treset MAC address to hardware default"
  echo -e "\t-v\t\tverbose output"
  echo -e "\n"
}

#flags and such

r=false
R=false
c=false
p=false
v=false
MAC=""

#parse options and arguments

while getopts ":hrRcpm:i:vd" opt; do
  case ${opt} in
    h) #process -h
      usage
      exit 1
      ;;
    r)
      r=true
      ;;
    R)
      R=true
      ;;
    c)
      c=true
      ;;
    p)
      p=true
      ;;
    v)
      v=true  
      ;;
    :)
      echo "[!] Option requires an argument."
      exit 0
      ;;
    \?)
      echo "[!] Invalid option."
      exit 0
      ;;
  esac
done
shift $((OPTIND -1))

#before going any further check if running as root

if [ "$EUID" -ne 0 ]
  then
    echo "[!] changemac must be run as root"
    exit 1
fi

#check for remaining arguments

if [ $# -gt 2 ]; then
  echo "[!] Too many arguments provided."
  exit 0
elif [ ! $# = 0 ]; then
  iface=$1
  if [ ! "$2" = "" ]; then
    MAC=$2
  fi 
fi

#check whether conflicting options were specified

if [ $r = true -a $R = true ]; then
  echo "[!] Cannot use both -r -R options"
  exit 1
fi

#function tests whether a supplied MAC address has valid formatting

function checkMAC {
  if [[ $1 =~ ([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2} ]]; then
    return 1
  else
    echo "[!] $MAC is not a valid MAC address"
    return 0
  fi
}

if [ ! "$MAC" = "" ]; then
  while checkMAC $MAC; do
    echo "[>] Please enter a valid MAC address"
    read MAC
  done
fi

#check for valid interface by retrieving its permanent MAC address

function getPermMAC {
  pMAC=$(networksetup -getmacaddress $1 | grep -oE '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
  if [ $? -eq 0 ]; then
    return 1
  else
    return 0
  fi
}

while getPermMAC $iface; do
  echo "[>] Please specify valid a network interface"
  read iface
done

if [ $p = true ]; then
  echo "[+] Permanent MAC Address: $pMAC"
fi

if [ $R = true ]; then
  MAC=$pMAC
fi

#store the current MAC address of the interface

cMAC=$(ifconfig $iface ether | grep -oE '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')

if [ $c = true ]; then
  echo "[+] Current MAC Address: $cMAC"
fi

#check MAC != cMAC

if [ "$cMAC" = "$MAC" ]
  then
    echo "[!] Current MAC already $MAC"
    exit 1
fi

#check if any options set that request a change of MAC address

if [ $r = true -o $R = true -o ! "$MAC" = "" -o ! "$iface" = "" -a ! $p = true -a ! $c = true ]; then

  #check if a Wi-Fi interface

  airport_status=$(networksetup -getairportpower $iface | grep -oE 'On|Off')

  if [ $? -eq 1 ]
    then
      wifi=false;
    else
      wifi=true;
  fi

  #if a Wi-Fi interface, turn it on if it's off

  if [ $wifi = true ]; then
    if [ "$airport_status" = "Off" ]; then
      if [ $v = true ]; then
        echo "[*] Powering on Wi-Fi interface"
      fi
      networksetup -setairportpower $iface on
    elif [ "$airport_status" = "On" ]; then
      if [ $v = true ]; then
        echo "[+] Wi-Fi interface is on"
      fi
    fi

    #detach from current AP before making changes
    #you'll have to manually reconnect afterwards

    if [ $v = true ]; then
      echo "[*] Dissociating from current AP"
    fi
    sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -z
  fi

  #nice! let's get to changing that MAC!
  if [ $v = true ]; then
    echo "[*] Changing MAC on interface: $iface"
  fi
  #randomly generate MAC address and assign to interface

  attempts=0

  function genMac {
    lastmac=$(ifconfig $iface ether | grep -oE '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
    if [ -z $MAC ]; then
      openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//' | xargs sudo ifconfig $iface ether 2> /dev/null
    else
      sudo ifconfig $iface ether $MAC 2> /dev/null
    fi
    newmac=$(ifconfig $iface ether | grep -oE '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
    ((attempts++))
  }

  #attempt to set new MAC, fail after 10 tries

  while [ $newmac = $lastmac -a $attempts -lt 10 ]; do
    genMac
  done

  if [ $attempts -ge 10 ]; then
    if [ $v = true ]; then
      echo "[!] Max retries (10) reached"
    fi
      echo "[!] Failed to change MAC address"
    exit 1
  fi

  if [ $v = true ]; then
    echo "[+] Last MAC: $lastmac"
  fi
    echo "[+] New MAC: $newmac"
fi

exit 0
