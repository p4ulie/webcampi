# Raspberry Pi OS Lite 64-bit

## Install dependencies
https://thepi.io/how-to-use-your-raspberry-pi-as-a-wireless-access-point/

```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install hostapd dnsmasq iptables bridge-utils
```

## 4G connection configuration

- https://snapcraft.io/install/modem-manager/raspbian
- https://ubuntu.com/core/docs/networkmanager/configure-cellular-connections


```
sudo apt install modemmanager
sudo apt install network-manager
```

```
mmcli -L
```

If modem is on device 0, enable it (change device number if different:

```
mmcli -m 0 -e
```

Configure connection:
```
nmcli c add type gsm ifname '*' con-name telekomsk apn internet
nmcli r wwan on
nmcli c modify telekomsk connection.autoconnect yes
```


## Static IP addresses

- https://www.daemon-systems.org/man/dhcpcd.conf.5.html

`sudo vi /etc/dhcpcd.conf`

```
interface br0
static ip_address=192.168.200.1/24

#interface wlan0
#static ip_address=192.168.200.1/24
#interface eth0
#static ip_address=192.168.200.2/24

denyinterfaces eth0
denyinterfaces wlan0
denyinterfaces br0
```

If necessary, delete default route
```
ip r del default dev eth0
```

## DHCP server and WiFi Access Point

- https://www.tecmint.com/setup-a-dns-dhcp-server-using-dnsmasq-on-centos-rhel/
- https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html

```
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo vi /etc/dnsmasq.conf
```

```
interface=br0
  dhcp-range=192.168.200.101,192.168.200.130,255.255.255.0,24h
  dhcp-host=14:eb:b6:b4:d1:49,192.168.200.5
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

- https://serverfault.com/questions/140622/how-can-i-port-forward-with-iptables

iptables rule

```
sudo iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE
sudo iptables -t nat -A PREROUTING -i ppp0 -p tcp --dport 22 -j DNAT  --to-destination 192.168.200.1:22
sudo iptables -A FORWARD -i ppp0 -o br0 -p tcp --dport 22 -j ACCEPT
#sudo iptables -A FORWARD -i ppp0 -o br0 -p tcp --dport 22 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
```

`sudo vi /etc/rc.local`

```
iptables-restore < /etc/iptables.ipv4.nat
```

## Bridge

`sudo vi /etc/network/interfaces`

```
auto br0
iface br0 inet manual
bridge_ports eth0 wlan0
```

run commands:
```
sudo brctl addbr br0
sudo brctl addif br0 eth0
```

## AWS Route53 dynamic DNS

- https://tynick.com/blog/03-16-2020/pynamicdns-dynamic-dns-with-raspberry-pi-python-and-aws/

## SSH Access

- https://www.everythingcli.org/ssh-tunnelling-for-fun-and-profit-autossh/

`sudo vi /etc/systemd/system/autossh-cam-ssh-tunnel.service`

```
[Unit]
Description=AutoSSH tunnel service Cam and SSH
After=network.target

[Service]
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -M 0 -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -R 0.0.0.0:10554:192.168.200.102:554 -R 0.0.0.0:10022:192.168.200.100:22 ubuntu@webcampi-cloud.dyndns.p4ulie.net -i /home/paulie/.ssh/webcampi_auto_ssh
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

```
sudo systemctl enable autossh-cam-ssh-tunnel.service
sudo systemctl start autossh-cam-ssh-tunnel.service
sudo systemctl status autossh-cam-ssh-tunnel.service
```

# Camera setup

## Access

- https://github.com/markszabo/tapo-c200-timelapse
- https://www.tp-link.com/cz/support/faq/2680/

`rtsp://<username>:<password>@<ip_address>:554/stream1`


## Image capturing software

- https://github.com/markszabo/tapo-c200-timelapse

Dependencies:
```
sudo apt install libvlc-dev
sudo pip3 install python-vlc
```

Copy example and edit configuration
```
cp timelapseconfig.py_example timelapseconfig.py
```

```
*/10 * * * * /usr/bin/python3 /home/paulie/tapo-c200-timelapse/capture.py >> /tmp/timelapse.log
```

## FFMPEG

- https://stackoverflow.com/questions/34904548/how-to-grab-a-single-image-from-rtsp-stream-using-ffmpeg
- https://codingshiksha.com/tutorials/ffmpeg-command-to-take-screenshot-of-rtsp-stream-and-save-it-as-pngjpeg-image-file-in-command-line/
- https://gist.github.com/westonruter/4508842
- https://gist.github.com/alfonsrv/a788f8781fb1616e81a6b9cebf1ea2fa
- https://gist.github.com/tayvano/6e2d456a9897f55025e25035478a3a50#file-gistfile1-txt-L118

```
ffmpeg -y -i rtsp://<username>:<password>@<ip_address>:554/stream1 -vframes 1 do.jpg
```

or alternately:
```
url='rtsp://<username>:<password>@<ip_address>:554/stream1' ffmpeg -i $url -r 1 -vsync 1 -qscale 1 -frames:v 1 -f image2 images_$(date +%F_%H-%M-%S).jpg
```

## Script

[RTSP_grab/camera.py](RTSP_grab/camera.py)

[RTSP_grab/capture_cam.sh](RTSP_grab/capture_cam.sh)

### Service to run capture script

[capture_cam.service](capture_cam.service)

Create file and copy-paste content:

`sudo vi /etc/systemd/system/capture_cam.service`

```
sudo systemctl daemon-reload
sudo systemctl enable capture_cam.service
sudo systemctl start capture_cam.service
sudo systemctl status capture_cam.service
```

### Upload latest image to S3


#### Service (optional - camera.py does the copy to latest.jpg after upload)

[s3_upload_latest.sh](s3_upload_latest.sh)

[s3_upload_latest.service](s3_upload_latest.service)

Create file and copy-paste content:

`sudo vi /etc/systemd/system/s3_upload_latest.service`

```
sudo systemctl daemon-reload
sudo systemctl enable s3_upload_latest.service
sudo systemctl start s3_upload_latest.service
sudo systemctl status s3_upload_latest.service
```

### Sync to S3 (optional)

[s3_sync.sh](s3_sync.sh)

### Directory listing on S3

- https://github.com/nolanlawson/pretty-s3-index-html

### Autorefresh latest image

```html
<!DOCTYPE html>
<html>

<head>
  <title>TabaCam</title>
  <meta http-equiv="refresh" content="15">
  <style>
    img {
        max-width: 100%;
        object-fit: contain;
    }
  </style>
</head>

<body style="background-color:black;">
  <img src="latest.jpg">
  <p style="color:white">The code will reload after 15s.</p>
</body>

</html>
```

and set:
`aws configure set s3.max_concurrent_requests 1`

set the cron `crontab -e` by adding the line:
```
* * * * * /home/paulie/s3_sync.sh >> /home/paulie/s3_sync.log 2>&1
```
