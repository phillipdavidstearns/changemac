#!/bin/bash

# 1. Removes symlinks to changemac
# 2. Prompts user whether to remove coreutils
# 3. Prompts user whether to remove repository

#-----------------------check if running from the uninstall.sh directory-------------------------

if [[ ! -f $PWD/changemac.sh ]]; then
	echo "[!] cd to the directory where this uninstall script is located and try again."
	exit 1
fi

#-----------------------Remove changemac symlink-------------------------

LINK_PATH=$(which changemac)

function is_changemac_symlinked {
	if [[ -L $LINK_PATH ]]; then
		echo "[+] changemac symlinked at $LINK_PATH."
		return 0
	else
		echo "[!] changemac symlink not found."
		return 1
	fi
}

is_changemac_symlinked

if [[ $? == 0 ]]; then

	while true; do
	    read -p "[>] Do you wish to uninstall changemac? (y/n): " choice
	    case $choice in
	        [Yy]* )
				echo "[*] Removing symlink at $LINK_PATH"
				rm -f $LINK_PATH
				break
				;;
	        [Nn]* )
				echo "[+] Exiting."
				exit 0
				break
				;;
	        * ) echo "Please enter y or n";;
	    esac
	done
fi

#-----------------------Uninstall GNU coreutils-------------------------

# are GNU coreutils installed?

if [[ $(brew list | grep coreutils &>/dev/null; echo $?) == 0 ]]; then

	while true; do
	    read -p "[>] Do you wish to uninstall GNU coreutils? (y/n): " choice
	    case $choice in
	        [Yy]* )
				echo "[*] Uninstalling GNU coreutils with \`brew uninstall coreutils\`"
				brew uninstall coreutils
				if [[ ! $(brew list | grep coreutils &>/dev/null; echo $?) == 0 ]];then
					echo "[+] Successfully uninstalled GNU coreutils."
				else
			    	echo "[!] Failed to uninstall GNU coreutils."
			    fi
				break
				;;
	        [Nn]* )
				echo "[+] Skipping deinstallation of GNU coreutils."
				break
				;;
	        * ) echo "Please enter y or n";;
	    esac
	done
else
	echo "[!] GNU coreutils are not installed."
fi

#-----------------------Uninstall Repository-------------------------

if [[ -f $PWD/changemac.sh && ! $PWD == "/" ]]; then

	while true; do
	    read -p "[>] Do you wish to remove the directory $PWD and all it contents? (y/n): " choice
	    case $choice in
	        [Yy]* )
				echo "[*] Removing $PWD"
				rm -rf $PWD
				break
				;;
	        [Nn]* )
				echo "[+] Skipping removal of $PWD"
				break
				;;
	        * ) echo "Please enter y or n";;
	    esac
	done

	if [[ -d $PWD ]];then
		echo "[!] Failed to remove $PWD"
	else
    	echo "[+] Successfully removed $PWD"
    fi

else
	echo "[!] $PWD not removed."
fi

exit 0