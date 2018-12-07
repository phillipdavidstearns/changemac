# changemac.sh

A simple bash script to make changing/spoofing your MAC address easier on your OSX 10.13+ system. Inspired by macchanger. Yes, I'm reinventing the wheel in a very kludgy way.

Written by Phillip David Stearns 2018.

## Installation

I recommend cloning or repository into your `/usr/local/etc` directory:

```
cd /usr/local/etc
git clone https://github.com/phillipdavidstearns/changemac.git
```

Make the script executable:

```
sudo chmod +x /full/path/to/changemac.sh
example: sudo chmod +x /usr/local/etc/changemac/changemac.sh
```

Create a symbolic link to your executable `$PATH` like so:

```
ln -s /full/path/to/changemac.sh /usr/local/bin/changemac
example: ln -s /usr/local/etc/changemac/changemac.sh /usr/local/bin/changemac
```

You should then be able to run the script from anywhere using `changemac`.

## Usage

Display the usage help message by running `changemac -h`

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

Always run as root. The order of options and arguments is important. All options must be specified *before* supplying the `[interface]` and optional `[MAC]` arguments.

```
sudo changemac
```

If no interface argument is supplied, you'll be prompted for one. Use `ifconfig` prior to running `changemac` to return a list of devices. Those with a MAC address are acceptable and can be changed.

Optionally, you can supply `changemac` with an interface argument:

```
sudo changemac [interface]
```

This generates and attempts to set a random MAC address for the specified interface.

If a Wi-Fi interface is specified, it will be powered up if off or dissociated from the current network if on and connected. You will have to reconnect manually to the network.

After the MAC address is successfully set, the interface is brought down and up. This should reset the connection and the new MAC address settings should take effect. However, you may need to manually do this using the commands:

```
ifconfig [interface] down
ifconfig [interface] up
``` 

You can manually set a specified MAC address by running the command as follows:

```
sudo changemac [interface] [MAC address]
```

Note: Not all MAC addresses are valid. If you try to manually set an invalid MAC address, the script will fail and exit after 10 tries.

If you mess up, the script will generally tell you where you went wrong and exit without doing anything.

Enjoy!