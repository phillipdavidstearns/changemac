# changemac.sh

A simple bash script to make changing/spoofing your MAC address easier on your OSX 10.13+ system. Inspired by macchanger. Yes, I'm reinventing the wheel in a very kludgy way.

Written by Phillip David Stearns 2018.

## Dependencies

Firstly, this only has a remote chance of working on Mac OSX 10.13+

You should install homebrew if you haven't already.

Then install the GNU `coreutils`:

```
brew install coreutils
```

The script uses `networksetup` and `airport`. `airport` is presumed to be at the following location:

```
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport
```

## Installation

I recommend cloning or unzipping repository into your `/usr/local/src` directory. From the command line:

```
cd /usr/local/src
git clone https://github.com/phillipdavidstearns/changemac.git
```

Create a symbolic link to your executable `$PATH` like so:

```
ln -s /full/path/to/changemac.sh /usr/local/bin/changemac
example: ln -s /usr/local/src/changemac/changemac.sh /usr/local/bin/changemac
```

You should then be able to run the script from anywhere running `changemac` form the command line.

## Usage

Display the usage help message by running `changemac -h`

```
Usage: changemac [-hcprRsv] [interface] [MAC]
NOTE: Some network changes require your password
	-h		display this help message
	-c		show current MAC address
	-p		show permanent hardware MAC address
	-r		randomize MAC address
	-R		reset MAC address to hardware default
	-s		Specify OUI. Randomly choose from list, or provide your own.
	-v		verbose output... like for dubugging X^D
```


The order of options and arguments is important. All options must be specified *before* supplying the `[interface]` and optional `[MAC]` arguments. Since `sudo` is used for some of the networking related commands, you'll be prompted for your password.


You must supply `changemac` with an interface argument. Run `ifconfig` prior to running `changemac` to return a list of devices. Most of those with a MAC address are acceptable and can be changed.

### Basic Example:

```
changemac [interface]
```

This generates and attempts to set a random MAC address for the specified interface.

If a Wi-Fi interface is specified, it will be powered up if off or dissociated from the current network if on and connected. You will have to reconnect manually to the network.

After the MAC address is successfully set, the interface is brought down and up. This should reset the connection and the new MAC address settings should take effect. However, you may need to manually do this using the commands:

```
sudo ifconfig [interface] down
sudo ifconfig [interface] up
``` 

### Manually Set MAC Address

You can manually set a specified MAC address by running the command as follows:

```
changemac [interface] [MAC address]
```

Note: Not all MAC addresses are valid. If you try to manually set an invalid MAC address, the script will fail and exit after 10 tries.

If you mess up, the script will generally tell you where you went wrong and exit without doing anything.

### OUI

You can randomly generate a MAC address with a specifed OUI. Either provide the OUI manually:

```
changemac [interface] [MAC address]
```

Or provide a list of OUIs by specifying the file path:

```
changemac -s [interface]
```

OUI formats accepts are `xx:xx:xx` or `XX:XX:XX`

If you also specify a MAC address, the `-s` option will be overridden. The next update will allow you to manually set the last 3 octets and randomly select the OUI.

Enjoy!