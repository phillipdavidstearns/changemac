#!/bin/bash

#--------------------------------------------------------------------
#	A simple bash script to make changing/spoofing your MAC address
#	easier on your OSX 10.13+ system. Inspired by macchanger.
#	Yes, I'm reinventing the wheel in a very kludgy way.
#
#	Written by Phillip David Stearns 2018.
#	Last update 11/2019
#
#   Was written for OSX 10.13
#   Dependencies: networksetup, airport, openssl, GNU coreutils
#--------------------------------------------------------------------

#a helpful usage message

function usage {
	echo -e "\nUsage: changemac [-hcprRsv] [interface] [MAC]"
	echo -e "NOTE: Some network changes require your password"
	echo -e "\t-h\t\tdisplay this help message"
	echo -e "\t-c\t\tshow current MAC address"
	echo -e "\t-p\t\tshow permanent hardware MAC address"
	echo -e "\t-r\t\trandomize MAC address"
	echo -e "\t-R\t\treset MAC address to hardware default"
	echo -e "\t-s\t\tSpecify OUI. Randomly choose from list, or provide your own."
	echo -e "\t-v\t\tverbose output... like for dubugging X^D"
	echo -e "\n"
}

#flags and such

r=false
R=false
c=false
p=false
v=false
s=false
MAC=""
iface=""
slist=""
OUI=""

#parse options and arguments

while getopts ":hrRcpm:i:s:vd" opt; do
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
		m)
			MAC=${OPTARG}
			;;
		i)
			iface=${OPTARG}
			;;
		s)
			s=true
			slist=${OPTARG}
			if [[ $slist =~ ([[:xdigit:]]{1,2}:){2}[[:xdigit:]] ]]; then
				OUI=$slist
			elif [[ ! -f $slist ]]; then
				echo "[!] Spoof list at $slist not found"
				exit 1
			else
				OUI=$(shuf -n 1 $slist)
				if [[ ! $OUI =~ ([[:xdigit:]]{1,2}:){2}[[:xdigit:]] ]]; then
					echo "[!] $slist did not return a valid OUI"
					exit 1
				fi
			fi
			;;
		:)
			echo "[!] Option requires an argument."
			exit 1
			;;
		\?)
			echo "[!] Invalid option. Run with -h to view usage."
			exit 1
			;;
	esac
done
shift $((OPTIND -1))

#check for remaining arguments

if [ $# -gt 2 ]; then
  echo "[!] Too many arguments provided. Run with -h to view usage."
  exit 0
elif [ $# -gt 0 -a $# -le 2 ]; then
  iface=$1
  if [ ! "$2" = "" ]; then
    MAC=$2
  fi
else
	echo "[!] Must specify a network interface."
	exit 1
fi

#check whether conflicting options were specified

if [ $r = true -a $R = true ]; then
	echo "[!] Cannot use both -r -R options"
	exit 1
fi

#function tests whether a supplied MAC address has valid formatting

if [[ -n "$MAC" && ! $2 =~ ([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2} ]]; then
	echo "[!] $MAC is not a valid MAC address"
	exit 1
fi

#check for valid interface by retrieving its permanent MAC address
pMAC=$(networksetup -getmacaddress $iface | grep -oE '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')

if [ $? -eq 1 ]; then
	echo "[!] Network interface not found!"
	exit 1
fi

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
    echo "[+] Current MAC already set to: $MAC"
    exit 0
fi

#check if any options set that request a change of MAC address

if [ $r = true -o $R = true -o ! "$MAC" = "" -o ! "$iface" = "" -a ! $p = true -a ! $c = true ]; then

	#check if a Wi-Fi interface

	airport_status=$(networksetup -getairportpower $iface | grep -oE 'On|Off')

	if [ $? -eq 1 ]; then
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
#if not a wifi interface, force the interface down and back up to apply changes.
	else if [ $wifi = false ]; then
		if [ $v = true ]; then
			echo "[*] Bringing inface $iface down"
		fi
		sudo ifconfig $iface down
		sleep 0.5
		if [ $v = true ]; then
			echo "[*] Bringing inface $iface up"
		fi
		sudo ifconfig $iface up
		sleep 0.5
	fi
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
		if [ $s = "true" ];then
			sudo ifconfig $iface ether $OUI:$(openssl rand -hex 3 | sed 's/\(..\)/\1:/g; s/.$//') 2> /dev/null
		else
			openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//' | xargs sudo ifconfig $iface ether 2> /dev/null
		fi
	else
		sudo ifconfig $iface ether $MAC 2> /dev/null
	fi
	newmac=$(sudo ifconfig $iface ether | grep -oE '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
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

#our results

if [ $v = true ]; then
		echo "[+] Last used MAC: $lastmac"
fi
		echo "[+] MAC set to: $newmac"
fi

exit 0
