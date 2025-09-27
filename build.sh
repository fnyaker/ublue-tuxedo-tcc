#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"


# Debug helper: print decorated info about important directories and env
debug_rpmbuild_state() {
    echo
    echo "================================================================"
    echo "= RPMS BUILD DEBUG: $(date +'%Y-%m-%d %T %z')"
    echo "================================================================"
    echo "PWD: $(pwd)"
    echo "USER: $(id -un) UID: $(id -u)"
    echo "HOME: ${HOME:-}"
    echo "Environment snippets: RPMBUILD_HOME=${RPMBUILD_HOME:-}, HOME=${HOME:-}, RELEASE=${RELEASE:-}"
    echo
    echo "-- /tmp listing --"
    ls -la /tmp || true
    echo
    echo "-- /tmp/rpmbuild top-level --"
    ls -la /tmp/rpmbuild || true
    echo
    for d in /tmp/rpmbuild/{SOURCES,BUILD,BUILDROOT,RPMS,SRPMS,SPECS}; do
        echo "-- $d --"
        if [ -e "$d" ]; then
            ls -la "$d" || true
        else
            echo "(not present)"
        fi
        echo
    done

    echo "-- find /tmp/rpmbuild (depth 3) --"
    find /tmp/rpmbuild -maxdepth 3 -ls 2>/dev/null || true
    echo "================================================================"
    echo
}


### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
rpm-ostree install tmux

# ============ Some little Custom packages ===========
rpm-ostree install gnome-disk-utility

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

echo "\n[build.sh] Debug: state BEFORE rpmdev-setuptree"
debug_rpmbuild_state
rpmdev-setuptree
echo "\n[build.sh] Debug: state AFTER rpmdev-setuptree"
debug_rpmbuild_state

git clone https://github.com/fnyaker/tuxedo-drivers-kmod

echo "\n[build.sh] Debug: state AFTER git clone (before entering repo)"
debug_rpmbuild_state

cd tuxedo-drivers-kmod/

echo "\n[build.sh] Debug: state BEFORE tuxedo-drivers-kmod/build.sh"
debug_rpmbuild_state
./build.sh
echo "\n[build.sh] Debug: state AFTER tuxedo-drivers-kmod/build.sh"
debug_rpmbuild_state
cd ..

# Extract the Version value from the spec file
export TD_VERSION=$(cat tuxedo-drivers-kmod/tuxedo-drivers-kmod-common.spec | grep -E '^Version:' | awk '{print $2}')


rpm-ostree install ~/rpmbuild/RPMS/x86_64/akmod-tuxedo-drivers-$TD_VERSION-1.fc42.x86_64.rpm ~/rpmbuild/RPMS/x86_64/tuxedo-drivers-kmod-$TD_VERSION-1.fc42.x86_64.rpm ~/rpmbuild/RPMS/x86_64/tuxedo-drivers-kmod-common-$TD_VERSION-1.fc42.x86_64.rpm ~/rpmbuild/RPMS/x86_64/kmod-tuxedo-drivers-$TD_VERSION-1.fc42.x86_64.rpm

KERNEL_VERSION="$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"

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