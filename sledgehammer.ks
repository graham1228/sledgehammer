lang en_US.UTF-8
keyboard us
timezone UTC
auth --useshadow --enablemd5
# rebar1
rootpw --iscrypted $1$UwJdGUMy$ORqjDQIW//wt7sWY.xG9M0
selinux --disabled
firewall --disabled

repo --name=a-base    --baseurl=http://mirrors.kernel.org/centos/7/os/$basearch
repo --name=a-updates --baseurl=http://mirrors.kernel.org/centos/7/updates/$basearch
repo --name=a-extras  --baseurl=http://mirrors.kernel.org/centos/7/extras/$basearch
repo --name=a-lldpd   --baseurl=http://download.opensuse.org/repositories/home:/vbernat/CentOS_7/
repo --name=a-epel    --baseurl=http://mirrors.kernel.org/fedora-epel/7/$basearch

%packages
OpenIPMI
OpenIPMI-tools
aic94xx-firmware
audit
authconfig
banner
basesystem
bash
bsdtar
bzip2
bzr
comps-extras
coreutils
curl
dhclient
dmidecode
dosfstools
dpkg
e2fsprogs
efibootmgr
file
filesystem
firewalld
fuse
fuse-libs
fuse-ntfs-3g
gdisk
glibc
glibc.i686
gzip
hostname
initscripts
iproute
iprutils
iptables
iputils
jq
kbd
kernel
kernel-tools
kexec-tools
less
libsysfs
linux-firmware
lldpd
lshw
lvm2
man-db
mdadm
microcode_ctl
mktemp
ncurses
nfs-utils
ntfs-3g
ntfsprogs
ntp
openssh-clients
openssh-server
openssl-libs
parted
passwd
pciutils
plymouth
policycoreutils
procps-ng
python-pip
rdma
rootfiles
rpm
rsyslog
ruby
ruby-devel.x86_64
ruby-libs.x86_64
rubygems
setup
shadow-utils
stress
stress-ng
sudo
syslinux
systemd
tar
tcpdump
unzip
util-linux
vconfig
vim-enhanced
vim-minimal
wget
which
xfsdump
xfsprogs
yum
zlib
%end

%post --nochroot


cp start-up.sh "$INSTALL_ROOT/sbin/sledgehammer-start-up.sh"
chmod +x "$INSTALL_ROOT/sbin/sledgehammer-start-up.sh"
cp hammer.txt "$INSTALL_ROOT/etc/motd"
cp sshd_config "$INSTALL_ROOT/etc/ssh/sshd_config"
cp sledgehammer.service "$INSTALL_ROOT/etc/systemd/system/sledgehammer.service"
cp dhclient.conf "$INSTALL_ROOT/etc"
cp -a artifacts "$INSTALL_ROOT"

%end

%post
# For paranoia's sake
ln -sf usr/bin bin
ln -sf usr/sbin sbin
ln -sf usr/lib lib
ln -sf usr/lib64 lib64
rm /sbin/sushell
ln -sf usr/bin/bash sbin/sushell


# Hack to really turn down SELINUX
sed -i -e 's/\(^SELINUX=\).*$/\1disabled/' /etc/selinux/config
systemctl enable network
systemctl enable ntpd
# systemctl enable debug-shell.service
systemctl disable kdump
systemctl enable systemd-udev-settle.service
systemctl enable sledgehammer.service

# Setup and install curtin
tar -xvf /artifacts/curtin.tgz
(
  cd trunk.dist
  pip install -r requirements.txt
  python ./setup.py install
)
rm -rf trunk.dist

cp /artifacts/gohai /usr/bin/gohai
chmod 755 /usr/bin/gohai

# Setup wimlib
(cd /usr; tar -zxvf /artifacts/wimlib-bin.tgz)
/sbin/ldconfig

# Update some of the pieces to be more explicit with sledgehammer
cp /artifacts/issue /etc/issue
cp /artifacts/issue.net /etc/issue.net
cp /artifacts/sledgehammer_release /etc/sledgehammer_release
sed -i '$i export PS1="<sledgehammer> $PS1"' /etc/bashrc

rm -rf /artifacts

%end
