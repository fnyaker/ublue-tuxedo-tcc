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

# ============ Some little Custom packages ===========
rpm-ostree install gnome-disk-utility

# ============ Aurora Black Specific: Wireshark ===========
rpm-ostree install wireshark

#Exec perms for symlink script
chmod +x /usr/bin/fixtuxedo
#And autorun
systemctl enable /etc/systemd/system/fixtuxedo.service

#Build and install tuxedo drivers
# Get current kernel version
CURRENT_KERNEL=$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')
echo "Current kernel version: ${CURRENT_KERNEL}"

# Check if kernel-devel is already installed and get its version
INSTALLED_KERNEL_DEVEL=$(rpm -q kernel-devel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' 2>/dev/null || echo "none")
echo "Installed kernel-devel version: ${INSTALLED_KERNEL_DEVEL}"

rpm-ostree install rpm-build
rpm-ostree install rpmdevtools
rpm-ostree install kmodtool
rpm-ostree install rpmrebuild
rpm-ostree install curl
rpm-ostree install gcc make

# Use the installed kernel-devel version if it exists, otherwise install for current kernel
if [ "${INSTALLED_KERNEL_DEVEL}" != "none" ]; then
    echo "Using existing kernel-devel version: ${INSTALLED_KERNEL_DEVEL}"
    KERNEL_VERSION="${INSTALLED_KERNEL_DEVEL}"
else
    echo "Installing kernel-devel for current kernel: ${CURRENT_KERNEL}"
    rpm-ostree install "kernel-devel-${CURRENT_KERNEL}"
    KERNEL_VERSION="${CURRENT_KERNEL}"
fi

# Install akmods after kernel-devel is properly available
rpm-ostree install akmods



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

# KERNEL_VERSION was already set above based on available kernel-devel
echo "Building akmods for kernel version: ${KERNEL_VERSION}"

akmods --force --kernels "${KERNEL_VERSION}" --kmod "tuxedo-drivers-kmod"



# Build and install tuxedo-yt6801 drivers
cd /tmp

# Use the correct fixed repository that works with newer kernels (6.15+)
echo "Cloning fixed yt6801 repository with kernel 6.15+ compatibility..."
git clone https://github.com/h4rm00n/yt6801-linux-driver
cd yt6801-linux-driver

echo "Source directory contents:"
ls -la

# Follow the same build process as the spec file
echo "Building yt6801 module manually for kernel ${KERNEL_VERSION}..."

# Create build directory following spec file pattern
BUILD_DIR="/tmp/_kmod_build_${KERNEL_VERSION}"
mkdir -p "${BUILD_DIR}"

# Copy the src directory as the spec file does
if [ -d "src" ]; then
    echo "Copying src directory to build location..."
    cp -a src/* "${BUILD_DIR}/"
else
    echo "No src directory found, looking for source files in root..."
    # Some repositories might have source files in the root
    find . -name "*.c" -o -name "*.h" -o -name "Makefile" | head -10
    echo "Copying source files to build directory..."
    # Copy C files, headers, and Makefile
    find . -maxdepth 1 \( -name "*.c" -o -name "*.h" -o -name "Makefile" \) -exec cp {} "${BUILD_DIR}/" \;
fi

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