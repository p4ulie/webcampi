# Raspberry Pi OS Lite 64-bit

## Install dependencies
https://thepi.io/how-to-use-your-raspberry-pi-as-a-wireless-access-point/

```
sudo apt-get install hostapd dnsmasq
```

## Static IP addresses

- https://www.daemon-systems.org/man/dhcpcd.conf.5.html

`sudo vi /etc/dhcpcd.conf`

```
interface wlan0
static ip_address=192.168.200.1/24
interface eth0
static ip_address=192.168.200.2/24
denyinterfaces eth0
denyinterfaces wlan0
```

## DHCP server

- https://www.tecmint.com/setup-a-dns-dhcp-server-using-dnsmasq-on-centos-rhel/

```
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo vi /etc/dnsmasq.conf
```

## WiFi Access POint
```
interface=wlan0
  dhcp-range=192.168.200.101,192.168.200.130,255.255.255.0,24h
```

`sudo vi /etc/hostapd/hostapd.conf`

```
interface=wlan0
bridge=br0
ssid=ap
hw_mode=g
channel=1
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=<passphrase>
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
```

`sudo vi /etc/default/hostapd`

uncomment and edit line DAEMON_CONF:
```
DAEMON_CONF="/etc/hostapd/hostapd.conf"
```

## Traffic forwarding

`sudo vi /etc/sysctl.conf`

```
net.ipv4.ip_forward=1
```

## Firewall - iptables - NAT
iptables rule

```
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
```

`sudo vi /etc/rc.local`

```
iptables-restore < /etc/iptables.ipv4.nat
```

# 4G connection configuration

https://ubuntu.com/core/docs/networkmanager/configure-cellular-connections

```
snap install modem-manager
```
