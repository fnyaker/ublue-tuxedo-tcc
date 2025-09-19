#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"


### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
rpm-ostree install tmux

#Exec perms for symlink script
chmod +x /usr/bin/fixtuxedo
#And autorun
systemctl enable /etc/systemd/system/fixtuxedo.service

#Build and install tuxedo drivers
rpm-ostree install rpm-build
rpm-ostree install rpmdevtools
rpm-ostree install kmodtool
rpm-ostree install rpmrebuild
rpm-ostree install gcc make kernel-devel

export HOME=/tmp

cd /tmp

rpmdev-setuptree

git clone https://github.com/stoeps13/tuxedo-drivers-kmod

cd tuxedo-drivers-kmod/
./build.sh
cd ..

# Extract the Version value from the spec file
export TD_VERSION=$(cat tuxedo-drivers-kmod/tuxedo-drivers-kmod-common.spec | grep -E '^Version:' | awk '{print $2}')

# Get the architecture
ARCH=$(uname -m)

rpm-ostree install ~/rpmbuild/RPMS/${ARCH}/akmod-tuxedo-drivers-$TD_VERSION-1.fc42.${ARCH}.rpm ~/rpmbuild/RPMS/${ARCH}/tuxedo-drivers-kmod-$TD_VERSION-1.fc42.${ARCH}.rpm ~/rpmbuild/RPMS/${ARCH}/tuxedo-drivers-kmod-common-$TD_VERSION-1.fc42.${ARCH}.rpm ~/rpmbuild/RPMS/${ARCH}/kmod-tuxedo-drivers-$TD_VERSION-1.fc42.${ARCH}.rpm

KERNEL_VERSION="$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"

akmods --force --kernels "${KERNEL_VERSION}" --kmod "tuxedo-drivers-kmod"

# Build and install tuxedo-yt6801 drivers
cd /tmp

git clone https://github.com/theCalcaholic/tuxedo-yt6801-kmod
cd tuxedo-yt6801-kmod

# Build the yt6801 kmod
./build.sh

# Get the built RPM filename (note: package is named tuxedo-yt6801-kmod, not kmod-tuxedo-yt6801)
YT6801_RPM=$(ls ~/rpmbuild/RPMS/${ARCH}/tuxedo-yt6801-kmod-*.rpm)

# Try to install the package directly first
if rpm-ostree install "${YT6801_RPM}"; then
    echo "yt6801 driver installed successfully without workaround"
else
    echo "Failed to install directly, applying workaround for bogus dependency..."
    # Workaround for bogus dependency - rebuild the rpm without the kmod-tuxedo-yt6801-common dependency
    rpmrebuild --batch --notest-install --change-spec-requires="sed '/^Requires:.*kmod-tuxedo-yt6801-common/d'" "${YT6801_RPM}"
    
    # Find the rebuilt RPM (rpmrebuild puts it in /root/rpmbuild/RPMS by default)
    REBUILT_YT6801_RPM=$(ls /root/rpmbuild/RPMS/${ARCH}/tuxedo-yt6801-kmod-*.rpm | head -1)
    
    # Install the rebuilt yt6801 driver
    rpm-ostree install "${REBUILT_YT6801_RPM}"
fi

cd /tmp

#Hacky workaround to make TCC install elsewhere
mkdir -p /usr/share
rm /opt
ln -s /usr/share /opt

rpm-ostree install tuxedo-control-center

cd /
rm /opt
ln -s var/opt /opt
ls -al /

rm /usr/bin/tuxedo-control-center
ln -s /usr/share/tuxedo-control-center/tuxedo-control-center /usr/bin/tuxedo-control-center

sed -i 's|/opt|/usr/share|g' /etc/systemd/system/tccd.service
sed -i 's|/opt|/usr/share|g' /usr/share/applications/tuxedo-control-center.desktop

systemctl enable tccd.service

systemctl enable tccd-sleep.service

# this would install a package from rpmfusion
# rpm-ostree install vlc

#### Example for enabling a System Unit File


systemctl enable podman.socket
