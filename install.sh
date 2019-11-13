#!/bin/bash

# 1. Checks for airport, networksetup, homebrew, openssl, GNU coreutils
# 2. Installs missing dependencies where possible
# 3. Creates a symlink at /usr/local/bin by default or path supplied at $1
# 4. Creates a symlink at /usr/local/share/changemac/apple.lst

function is_changemac_installed {
	if [[ $(which changemac 2>/dev/null) ]]; then
		echo "[+] changemac installed at $(which changemac). Run changemac -h for usage."
		exit 0
	else
		return 1
	fi
}

is_changemac_installed

#-----------------------check if running from the install.sh directory-------------------------

if [[ ! -f $PWD/changemac.sh ]]; then
	echo "[!] cd to the directory where this installation script is located and try again."
	exit 1
else
	echo "[*] Installing changemac."
fi

#-----------------------setting the symlink path-------------------------

LINK_PATH=""

function set_link_path {
	echo "[+] changemac will be symlinked at /usr/local/bin/changemac"
	LINK_PATH="/usr/local/bin/changemac"
}

case $# in
	0)
		set_link_path
		;;
	1)
		if [[ -d $1 ]];then
			echo "[+] changemac will be symlinked at $1/changemac. Make sure it's in your \$PATH."
			LINK_PATH="$1/changemac"
		else
			echo "[!] $1 is not a valid directory."
			set_link_path
		fi	
		;;
	*)
		echo "[!] Too many arguments supplied"
		exit 1
		;;
esac

#-----------------------Check/Install Dependencies-------------------------

echo "[*] Checking dependencies"

AIRPORT_PATH="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"

#-----------------------Is airport installed?-------------------------

if [[ -x "$AIRPORT_PATH" ]]; then
	echo "[+] airport found at $AIRPORT_PATH"
	# Check whether airport is symlinked."
	if [[ $(which airport 2>/dev/null) ]]; then
		echo "[+] airport symlink found at $(which airport)"
	else
		echo "[*] Creating symlink to airport in /usr/local/bin, please enter your password if prompted."
		sudo ln -s "$AIRPORT_PATH" "/usr/local/bin/airport"
	fi
else
	echo "[!] airport not found at $AIRPORT_PATH"
	exit 1
fi

#-----------------------Is networksetup installed?-------------------------

if [[ $(which networksetup 2>/dev/null) ]]; then
	echo "[+] networksetup found at $(which networksetup)"
else
	echo "[!] networksetup not found."
	exit 1
fi

#-----------------------Is homebrew installed?-------------------------

if [[ $(which brew 2>/dev/null) ]]; then
	echo "[+] homebrew symlink found at $(which brew)"
else
	while true; do
	    read -p "[>] Homebrew is required to complete the installation. Do you wish to install? (y/n): " choice
	    case $choice in
	        [Yy]* )
				echo "[*] Installing homebrew with /usr/bin/ruby -e \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\""
				/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
				break
				;;
	        [Nn]* )
				exit 0
				;;
	        * ) echo "Please enter y or n";;
	    esac
	done
	if [[ $(which brew 2>/dev/null; echo $?) == 0 ]];then
		echo "[+] Successfully installed homebrew."
	else
    	echo "[!] Installation of homebrew failed!"
    	exit 1
    fi
fi

#-----------------------Is openssl installed-------------------------

if [[ $(brew list | grep openssl 2>/dev/null) ]]; then
	echo "[+] openssl already installed."
else
	while true; do
	    read -p "[>] openssl is required. Do you wish to install openssl? (y/n): " choice
	    case $choice in
	        [Yy]* )
				echo "[*] Installing openssl with \`brew install openssl\`"
				brew install openssl
				break
				;;
	        [Nn]* )
				exit 0
				;;
	        * ) echo "Please enter y or n";;
	    esac
	done
	if [[ $(brew list | grep openssl 2>/dev/null) ]];then
		echo "[+] Successfully installed openssl."
	else
    	echo "[!] Installation of openssl failed!"
    	exit 1
    fi
fi

#-----------------------Are GNU coreutils installed?-------------------------

if [[ $(brew list | grep coreutils 2>/dev/null) ]]; then
	echo "[+] coreutils already installed."
else
	while true; do
	    read -p "[>] GNU coreutils are required. Do you wish to install GNU coreutils? (y/n): " choice
	    case $choice in
	        [Yy]* )
				echo "[*] Installing GNU coreutils with \`brew install coreutils\`"
				brew install coreutils
				break
				;;
	        [Nn]* )
				exit 0
				;;
	        * ) echo "[>] Please enter y or n";;
	    esac
	done
	if [[ $(brew list | grep coreutils 2>/dev/null) ]];then
		echo "[+] Successfully installed coreutils."
	else
    	echo "[!] Installation of coreutils failed!"
    	exit 1
    fi
fi

#-----------------------Create Symlink-------------------------

function create_symlink {
	if [[ -L $LINK_PATH ]]; then
		echo "[*] changemac exists at $LINK_PATH"
	else
		echo "[*] Creating symlink at $LINK_PATH. Please enter your password if prompted."
		sudo ln -s $PWD/changemac.sh $LINK_PATH
		if [[ $? == 0 ]]; then
			echo "[+] Created symlink at $LINK_PATH"
		else
			echo "[!] Failed to create symlink at $LINK_PATH"
			exit 1
		fi
	fi
}

#-----------------------Is changemac.sh is executable?-------------------------

if [[ -x $PWD/changemac.sh ]]; then
	create_symlink
else
	echo "[*] Making changemac.sh executable."
	chmod +x $PWD/changemac.sh
	if [[ $? == 0 ]]; then
		create_symlink
	else
		echo "[!] Failed to make changemac.sh executable"
		exit 1
	fi
fi

is_changemac_installed

if [[ $? != 0 ]]; then
	echo "[!] changemac failed to install."
	exit 1
fi

#-----------------------THE END-------------------------

echo "we should never see this..."

exit 0