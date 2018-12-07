# changemac.sh

A simple bash script to make changing/spoofing your MAC address easier on your OSX 10.13+ system. Inspired by macchanger. Yes, I'm reinventing the wheel in a very kludgy way.

Written by Phillip David Stearns 2018.

## Installation

I recommend cloning or repository into your `/usr/local/opt` directory:

```
cd /usr/local/opt
git clone https://github.com/phillipdavidstearns/changemac.git
```

Make the script executable:

```
sudo chmod +x /full/path/to/changemac.sh
```

Create a symbolic link to your executable `$PATH` like so:

```
ln -s /full/path/to/changemac.sh /usr/local/bin/changemac
```

You should then be able to run the script from anywhere using `changemac`.

## Use

```
Usage: changemac [-hcprRv] [interface] [MAC]
NOTE: Must be run as root!

	-h		display this help message
	-c		show current MAC address
	-p		show permanent hardware MAC address
	-r		randomize MAC address
	-R		reset MAC address to hardware default
	-v		verbose output
```

Always run as root.

```
sudo changemac
```

If no interface argument is supplied, it'll prompt you for one. You can use `ifconfig` prior to running `changemac` to return a list of devices. Those with a MAC address are accepted and can be changed.

Optionally, you can supply `changemac` with an interface argument:

```
sudo changemac [interface]
```

This will attempt to generate and set a random MAC address.

If a Wi-Fi interface is specified, it will be powered up if off or dissociated from the current network if on and connected. You will have to reconnect to the network.

Right now, other network interfaces are not detached, so will have to be manually placed `down` and `up` for the changes to take effect:

```
ifconfig <interface> down
ifconfig <interface> up
``` 

You can manually set a specified MAC address by running the command as follows:

```
sudo changemac <interface> <MAC address>
```

Note: Not all MAC addresses are valid. If you try to manually set an invalid MAC address, the script will fail and exit after 10 tries.

If you mess up, the script will generally tell you where you went wrong and exit without doing anything.

Enjoy!