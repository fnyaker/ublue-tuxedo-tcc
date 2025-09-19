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

# Instead of using their build script, let's manually build the module following the spec file approach
echo "Building yt6801 module manually for kernel ${KERNEL_VERSION}..."

# Create build directory
BUILD_DIR="/tmp/yt6801_build_${KERNEL_VERSION}"
mkdir -p "${BUILD_DIR}"

# Copy source files
cp -a src/* "${BUILD_DIR}/"

# Build the module for our specific kernel
cd "${BUILD_DIR}"
make V=1 -C "/lib/modules/${KERNEL_VERSION}/build" M="${BUILD_DIR}" modules

# Install the module
MODULE_INSTALL_DIR="/lib/modules/${KERNEL_VERSION}/extra/tuxedo-yt6801"
mkdir -p "${MODULE_INSTALL_DIR}"

# Find and install the built .ko files
find "${BUILD_DIR}" -name "*.ko" -exec install -D -m 755 {} "${MODULE_INSTALL_DIR}/" \;

# Update module dependencies
depmod -a "${KERNEL_VERSION}"

echo "yt6801 module installation completed"

# Verify the module was built and installed
echo "Verifying yt6801 module installation..."
find /lib/modules/${KERNEL_VERSION}/extra -name "*yt6801*" | head -5

# Check if modinfo can find it
echo "Checking if module is available to modinfo..."
modinfo yt6801 2>/dev/null && echo "yt6801 module found!" || echo "yt6801 module not found by modinfo"

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
