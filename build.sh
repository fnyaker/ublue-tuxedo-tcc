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
rpm-ostree install curl
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

# Use the official Tuxedo GitLab source as specified in the spec file
echo "Downloading official tuxedo-yt6801 source from GitLab..."
YT6801_VERSION="1.0.30tux2"
YT6801_URL="https://gitlab.com/tuxedocomputers/development/packages/tuxedo-yt6801/-/archive/v${YT6801_VERSION}/tuxedo-yt6801-v${YT6801_VERSION}.tar.gz"

# Download and extract the source
curl -L "${YT6801_URL}" -o "tuxedo-yt6801-v${YT6801_VERSION}.tar.gz"
tar -xzf "tuxedo-yt6801-v${YT6801_VERSION}.tar.gz"

# Rename to match what we expect (the tar might extract to tuxedo-yt6801-v1.0.30tux2-<hash>)
YT6801_EXTRACTED_DIR=$(find . -maxdepth 1 -name "tuxedo-yt6801-v${YT6801_VERSION}*" -type d | head -1)
if [ -z "$YT6801_EXTRACTED_DIR" ]; then
    echo "Failed to find extracted directory"
    exit 1
fi

mv "$YT6801_EXTRACTED_DIR" "tuxedo-yt6801-v${YT6801_VERSION}"
cd "tuxedo-yt6801-v${YT6801_VERSION}"

echo "Source directory contents:"
ls -la

# Follow the exact same process as the spec file
echo "Building yt6801 module manually for kernel ${KERNEL_VERSION}..."

# Create build directory following spec file pattern
BUILD_DIR="/tmp/_kmod_build_${KERNEL_VERSION}"
mkdir -p "${BUILD_DIR}"

# Copy the src directory as the spec file does
if [ -d "src" ]; then
    echo "Copying src directory to build location..."
    cp -a src/* "${BUILD_DIR}/"
else
    echo "ERROR: No src directory found in the official source!"
    ls -la
    exit 1
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
