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

# Debug: List what was actually built
echo "=== YT6801 Build Results ==="
ls -la ~/rpmbuild/RPMS/${ARCH}/
echo "=== End Build Results ==="

# Check what files are in the tuxedo-yt6801-kmod package
echo "=== Contents of tuxedo-yt6801-kmod package ==="
rpm -qlp ~/rpmbuild/RPMS/${ARCH}/tuxedo-yt6801-kmod-*.rpm | head -20

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

# Now check if the package contains pre-built modules or if we need to build them manually
echo "Checking for pre-built modules in the installed package..."
rpm -ql tuxedo-yt6801-kmod | grep -E "\.ko(\.xz|\.gz)?$" || echo "No pre-built modules found"

# Check if there's source code we need to build manually
YT6801_SRC_DIR="/usr/src/tuxedo-yt6801"
if [ -d "$YT6801_SRC_DIR" ] || [ -d "/usr/src/tuxedo-yt6801-*" ]; then
    echo "Found source directory, building manually..."
    
    # Find the actual source directory
    ACTUAL_SRC_DIR=$(find /usr/src -maxdepth 1 -name "tuxedo-yt6801*" -type d | head -1)
    if [ -n "$ACTUAL_SRC_DIR" ]; then
        echo "Building from source in: $ACTUAL_SRC_DIR"
        cd "$ACTUAL_SRC_DIR"
        
        # Build the module
        make clean
        make KDIR="/lib/modules/${KERNEL_VERSION}/build"
        
        # Install the module
        make install KDIR="/lib/modules/${KERNEL_VERSION}/build" INSTALL_MOD_PATH=""
        
        # Update module dependencies
        depmod -a "${KERNEL_VERSION}"
        
        echo "Manual build completed"
    fi
else
    echo "No source directory found, checking if this is a different type of package..."
    
    # List all files in the package to see what we actually got
    echo "All files in tuxedo-yt6801-kmod package:"
    rpm -ql tuxedo-yt6801-kmod
fi

# Final verification
echo "Final check for yt6801 module..."
find /lib/modules/${KERNEL_VERSION} -name "*yt6801*" -o -name "*tuxedo-yt6801*" | head -5

# Also check if modinfo can find it
echo "Checking if module is available to modinfo..."
modinfo yt6801 2>/dev/null || modinfo tuxedo-yt6801 2>/dev/null || echo "Module not found by modinfo"

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
