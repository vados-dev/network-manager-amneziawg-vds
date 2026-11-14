#!/usr/bin/env bash

restart_services() {
systemctl daemon-reload
systemctl restart NetworkManager
}

awg_nm_update() { git fetch origin master; git pull origin master; }

# gtk3-devel  "libnma-devel"
awg_nm_deps=("cmake" "gcc" "g++" "pkg-config" "intltool" "NetworkManager-libnm-devel" "glib2-devel" "gettext" "rpm-build")

install_packages() {
    local packages=("$@")
    local to_install=()
    local rpm_pkg
    echo "Checking for installing packages: ${packages[*]}..."
    for rpm_pkg in "${packages[@]}"; do
        if ! dnf list installed "$rpm_pkg" | grep -q "Installed Packages"; then
            to_install+=("$rpm_pkg")
        fi
    done
        if [ ${#to_install[@]} -eq 0 ]; then
            echo "All rpm packages already installed."
            return 0
        else
            echo ${to_install[*]}
        fi

    dnf clean all || true
    dnf makecache || true

    echo "Installing: ${to_install[*]}..."
    sudo dnf install -y ${to_install[*]} > /dev/null 2>&1 || { echo "Error install packages"; exit 1; }
}

installed=$(dnf list installed | grep networkmanager-amneziawg | awk '{print $1}')
dnf remove -y $installed || true

install_packages ${awg_nm_deps[@]}

rm -rf ./build || true

awg_nm_update

restart_services
#exit 0

mkdir -p build && cd build
# System installation (for RPM packages)
#
cmake .. -DWITH_GTK3=OFF -DWITH_GTK4=OFF -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib64
cmake --build .
cpack -G RPM
#rpm -i NetworkManager-amneziawg-*.rpm
dnf install $(ls | grep NetworkManager-amneziawg-*.rpm)

restart_services
