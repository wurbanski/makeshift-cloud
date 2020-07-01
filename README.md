# makeshift-cloud

## Introduction (in Polish)

[![Nine Fives Labs: \[04\] Masz Linuksa? Masz chmurę!* ](https://img.youtube.com/vi/ZqDPaKCvkfU/0.jpg)](https://www.youtube.com/watch?v=ZqDPaKCvkfU)

## Create network

```text
$ ./add-network.sh -h
Required parameters:
	-n	network name
	-a	address range (e.g. 192.168.123.1/24)
Optional parameters:
	-d	domain to use for the network
```

## Pull images (and setup directory structure)

```text
$ ./pull-images.sh
[...]
```

## Create VM

```text
$ ./spawn-vm.sh -h
Required parameters:
	-n	<server name>
	-d	<linux distro>

Optional parameters
-s	<main disk size, for example: '-s 10G' >
-c	<virsh connection string>
-i	<network name to use with main network interface>
```
