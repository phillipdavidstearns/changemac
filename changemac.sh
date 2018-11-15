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

#check if running as root

if [ "$EUID" -ne 0 ]
  then
    echo "[!] Please run as root"
    echo "[!] Exiting"
    exit 1
fi

#check to see if a wireless interface was provided

if [ $# -eq 0 ]
  then
    echo "[!] Please specify a wireless interface"
    read iface
  elif [ $# -eq 1 ]
    then
      iface=$1
      MAC=''
  elif [ $# -eq 2 ]
    then
      iface=$1
      if [[ ${2} =~ ([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2} ]]
        then
          MAC=$2
        else
          echo "[!] Not a valid MAC address"
          echo "[!] Exiting"
          exit 1
      fi
  else
    echo "[!] Too many arguments"
    echo "[!] Exiting"
    exit 1   
fi

#store the permanent MAC address of the interface

permmac=$(networksetup -getmacaddress $iface | grep -oE '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')

#if retrieving MAC failed, exit

if [ $? -eq 1 ]
  then
    echo "[!] Invalid interface"
    echo "[!] Exiting"
    exit 1
fi

#store the current MAC address of the interface

currentmac=$(ifconfig $iface ether | grep -oE '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')

#check MAC != currentmac

if [[ $currentmac = $MAC ]]
  then
    echo "[!] Current MAC already $MAC"
    echo "[!] Exiting"
    exit 1
fi

#check if a Wi-Fi interface

airport_status=$(networksetup -getairportpower $iface | grep -oE 'On|Off')

if [ $? -eq 1 ]
  then
    wifi=false;
  else
    wifi=true;
fi

#if a Wi-Fi interface, turn it on if it's off

if [ $wifi = true ]
  then
    if [ $airport_status = 'Off' ]
      then
        echo "[+] Powering on Wi-Fi interface"
        networksetup -setairportpower $iface on
      elif [ $airport_status = 'On' ]
        then
          echo "[+] Wi-Fi interface is on"
      else
        echo "[!] Something's broken..."
        echo "[!] Exiting"
        exit 1
    fi

    #detach from current AP before making changes
    #you'll have to manually reconnect afterwards

    echo "[+] Dissociating from current AP"
    sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -z

fi

#nice! let's get to changing that MAC!

echo "[+] Changing MAC on interface: $iface"
echo "[+] Permanent MAC: $permmac"

#randomly generate MAC address and assign to interface

attempts=0

function genMac {
        lastmac=$(ifconfig $iface ether | grep -oE '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
        if [[ $MAC = '' ]]
          then
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

if [ $attempts -ge 10 ]
  then
    echo "[!] Max retries (10) reached"
    echo "[!] MAC address not changed"
    exit 1
fi

echo "[+] Last MAC: $lastmac"
echo "[+] New MAC: $newmac"

exit 0