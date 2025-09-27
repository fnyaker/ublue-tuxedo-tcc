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

# Get the kernel version after installing kernel-devel
KERNEL_VERSION="$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
echo "Using kernel version for build: ${KERNEL_VERSION}"

export HOME=/tmp

cd /tmp

rpmdev-setuptree

git clone https://github.com/stoeps13/tuxedo-drivers-kmod

cd tuxedo-drivers-kmod/

# Manually download the source if spectool fails
TD_VERSION_FOR_DOWNLOAD=$(grep "Version:" tuxedo-drivers-kmod.spec | awk '{print $2}')

# Try the correct GitLab archive URL format
SOURCE_URL="https://gitlab.com/tuxedocomputers/development/packages/tuxedo-drivers/-/archive/v${TD_VERSION_FOR_DOWNLOAD}/tuxedo-drivers-v${TD_VERSION_FOR_DOWNLOAD}.tar.gz"
SOURCE_FILE="$HOME/rpmbuild/SOURCES/v${TD_VERSION_FOR_DOWNLOAD}.tar.gz"

# Create SOURCES directory
mkdir -p $HOME/rpmbuild/SOURCES/

# Always try spectool first as it handles the URL correctly
echo "Trying spectool to download source..."
spectool -g -R $HOME/rpmbuild/SPECS/tuxedo-drivers-kmod.spec || {
    echo "spectool failed, trying manual download..."
    
    # Check if the file exists and verify it's a valid gzip
    if [ -f "${SOURCE_FILE}" ]; then
        echo "Checking if existing file is valid..."
        if ! file "${SOURCE_FILE}" | grep -q "gzip compressed"; then
            echo "Existing file is not valid gzip, removing it..."
            rm -f "${SOURCE_FILE}"
        fi
    fi
    
    # Try manual download with better error handling
    echo "Downloading tuxedo-drivers source from ${SOURCE_URL}"
    if curl -L -f -o "${SOURCE_FILE}" "${SOURCE_URL}"; then
        # Verify the downloaded file is actually a gzip file
        if file "${SOURCE_FILE}" | grep -q "gzip compressed"; then
            echo "Source downloaded successfully and verified as gzip"
        else
            echo "Downloaded file is not a valid gzip file. Content:"
            head -20 "${SOURCE_FILE}"
            echo "Trying alternative URL formats..."
            
            # Try alternative URL format
            ALT_URL="https://gitlab.com/tuxedocomputers/development/packages/tuxedo-drivers/-/archive/v${TD_VERSION_FOR_DOWNLOAD}.tar.gz"
            echo "Trying alternative URL: ${ALT_URL}"
            curl -L -f -o "${SOURCE_FILE}" "${ALT_URL}" || {
                echo "All download attempts failed. Cannot proceed with build."
                exit 1
            }
        fi
    else
        echo "Failed to download source file from ${SOURCE_URL}"
        exit 1
    fi
}

./build.sh
cd ..

# Extract the Version value from the spec file
export TD_VERSION=$(cat tuxedo-drivers-kmod/tuxedo-drivers-kmod-common.spec | grep -E '^Version:' | awk '{print $2}')

# Get the architecture
ARCH=$(uname -m)

rpm-ostree install ~/rpmbuild/RPMS/${ARCH}/akmod-tuxedo-drivers-$TD_VERSION-1.fc42.${ARCH}.rpm ~/rpmbuild/RPMS/${ARCH}/tuxedo-drivers-kmod-$TD_VERSION-1.fc42.${ARCH}.rpm ~/rpmbuild/RPMS/${ARCH}/tuxedo-drivers-kmod-common-$TD_VERSION-1.fc42.${ARCH}.rpm ~/rpmbuild/RPMS/${ARCH}/kmod-tuxedo-drivers-$TD_VERSION-1.fc42.${ARCH}.rpm

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
