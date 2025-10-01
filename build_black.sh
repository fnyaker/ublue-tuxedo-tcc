#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# ============================================================
# Black Variant Specific Packages
# ============================================================
# This script installs additional packages specific to the "Black" variant
# These are security/networking tools not in the base image

echo "Installing Black variant specific packages..."

# ============ Network Security Tools ===========
rpm-ostree install wireshark
rpm-ostree install aircrack-ng

echo "Black variant specific packages installation completed!"
