#  Inception-of-Things

## First steps

### Installation of Vagrant and Virtualbox

+ Install Vagrant:

> wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
> echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
> sudo apt update && sudo apt install vagrant

## Troubleshooting

Sometimes the IP range specified in the private network overlaps a network already in use on the machine, such as a Docker network. This can give the following error:

==> nponchonS: Clearing any previously set network interfaces...
The specified host network collides with a non-hostonly network!
This will cause your specified IP to be inaccessible. Please change
the IP or name of your host only network so that it no longer matches that of
a bridged or non-hostonly network.

Bridged Network Address: '192.168.56.0'
Host-only Network 'br-d2c21f32a5cf': '192.168.56.0'

The command `ip a` gives us the confirmation that the IP range is being used by another device:

nponchon@nponchon-VirtualBox:~/Desktop/Inception-of-Things/p1$ ip a
[...]
4: br-d2c21f32a5cf: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 06:80:b1:9e:f7:6a brd ff:ff:ff:ff:ff:ff
    inet *192.168.56.1/24* brd 192.168.56.255 scope global br-d2c21f32a5cf
       valid_lft forever preferred_lft forever
[...]

You can run `docker network ls` to check whether Docker is using the network or not, and then remove it with `docker netowrk rm <network>`.
Another way to clear the IP range is to use the command `sudo ip link delete <network>`

