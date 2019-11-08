#!/bin/sh
# Copyright 2018-2019 Alkis Georgopoulos <github.com/alkisg>
# SPDX-License-Identifier: GPL-3.0-or-later

usage() {
    printf "Usage: %s [OPTIONS] [COMMAND]

Install the drivers for the BrosTrend AC1/AC3 adapters.
The main difficulty is in detecting the appropriate kernel *headers* package.

Options:
    -h  Show this help message.
    -p  Pause on exit.
" "$0"
}

bold() {
    if [ "$_PRINTBOLD_FIRST_TIME" != 1 ]; then
        _PRINTBOLD_FIRST_TIME=1
        _BOLD_FACE=$(tput bold 2>/dev/null) || true
        _NORMAL_FACE=$(tput rmso 2>/dev/null) || true
    fi
    if [ "$1" = "-n" ]; then
        shift
        printf "%s" "${_BOLD_FACE}$*${_NORMAL_FACE}"
    else
        printf "%s\n" "${_BOLD_FACE}$*${_NORMAL_FACE}"
    fi
}

# Output a message to stderr and abort execution
die() {
    bold "$@" >&2
    pause_exit 1
}

pause_exit() {
    local dummy

    if [ "$_PAUSE_ON_EXIT" = 1 ]; then
        bold -n "Press [Enter] to close the current window."
        read -r dummy
    fi
    exit "$1"
}

request_info() {
    bold "System information:"
    uname -a
    grep PRETTY /etc/os-release
    ls /lib/modules
    dpkg -l "*$(uname -r)*" | grep "$(uname -r)"
    dkms status
    die "
===================================================
 ERROR: The driver was NOT successfully installed!
===================================================
Please select all the text in this terminal, then right click with the
mouse and select Copy, and finally paste all the text in an email to:
    support@trend-tech.net.cn"
}

install_kernel_headers() {
    local kernel header headers

    # If the appropriate headers are already installed, return
    test -f "/usr/src/linux-headers-$(uname -r)/Makefile" && return 0

    # We assume that the linux-image package name doesn't contain a dot.
    # Possible names:
    # Ubuntu: https://packages.ubuntu.com/source/bionic/linux-meta
    # E.g. linux-image-generic, linux-image-lowlatency-hwe-16.04
    # Debian: https://packages.debian.org/source/stretch/linux-latest
    # E.g. linux-image-686, linux-image-amd64, linux-image-armmp
    # Raspbian: raspberrypi-kernel
    headers=""
    for kernel in $(dpkg -l 'linux-image*' raspberrypi-kernel 2>/dev/null |
        awk '/^ii/ { print $2 }' | fgrep -v .)
    do
        case "$kernel" in
            raspberrypi-kernel)
                header=raspberrypi-kernel-headers ;;
            *)
                header=$(echo "$kernel" | sed 's/image/headers/') ;;
        esac
        if apt-cache policy "$header" | grep -q '[0-9]'; then
            headers="$headers $header"
        fi
    done
    if [ -n "$headers" ]; then
        bold "Installing kernel headers:$headers"
        apt-get install --yes $headers || die "Couldn't install kernel headers"
    else
        bold "Couldn't detect the appropriate kernel headers package!" >&2
        request_info
    fi
}

# Sets $_CHIP, based on the script filename, or the inserted adapter,
# or the user input.
# lsusb output:
# V1: Bus 003 Device 008: ID 0bda:8812 Realtek Semiconductor Corp.
#     RTL8812AU 802.11a/b/g/n/ac WLAN Adapter
# V2: Bus 003 Device 007: ID 0bda:b812 Realtek Semiconductor Corp.
# V3: Bus 003 Device 027: ID 0bda:c811 Realtek Semiconductor Corp.
detect_adapter() {
    local fname product choice

    _CHIP=""
    fname=${0##*/}
    fname=${fname%.sh}
    case "$fname" in
        8812au|88x2bu|8821cu) _CHIP=$fname; return 0 ;;
    esac
    while [ -z "$_CHIP" ]; do
        for product in $(lsusb | grep -o '\b0bda:[0-9a-f]\{4\}\b'); do
            case "$product" in
                0bda:8812) _CHIP=8812au ;;
                0bda:b812) _CHIP=88x2bu ;;
                0bda:c811) _CHIP=8821cu ;;
            esac
        done
        test -n "$_CHIP" && return 0
        bold "Could not detect the adapter!"
        echo "Please insert the BrosTrend WiFi adapter into a USB slot
and press [Enter] to continue.
If you don't have the adapter currently, you may type:
  (a) to install the 8812au driver for the first version of the adapter, or
  (b) to install the 88x2bu driver for the second version of the adapter, or
  (c) to install the 8821cu driver for the third version of the adapter, or
  (q) to quit without installing a driver"
        bold -n "Please type your choice, or [Enter] to autodetect: "
        read -r choice
        case "$choice" in
            a) _CHIP=8812au ;;
            b) _CHIP=88x2bu ;;
            c) _CHIP=8821cu ;;
            q) die "Aborted"
        esac
    done
}

main() {
    local title scriptpath ret

    case "$1" in
        "") ;;
        -p) _PAUSE_ON_EXIT=1 ;;
        *)  usage; exit 0 ;;
    esac

    # First check if we need to spawn an x-terminal-emulator.
    # Note that after pkexec we don't have access to $DISPLAY.
    if [ "$_PAUSE_ON_EXIT" != 1 ] && { [ ! -t 0 ] || [ ! -t 1 ] ;} &&
        xmodmap -n >/dev/null 2>&1
    then
        title=${1##*/}
        case "$title" in
            -s|--source) title=${2##*/} ;;
            '') title=${0##*/} ;;
        esac
        _PAUSE_ON_EXIT=1 exec x-terminal-emulator -T "$title" -e sh "$0" "$@"
    fi

    # Get root access if we don't already have it
    if [ $(id -u) -ne 0 ]; then
        # Make the installer executable, in case it was downloaded from the web.
        scriptpath="$(cd "$(dirname "$0")" ; pwd -P)/$(basename "$0")"
        test -x "$scriptpath" || chmod +x "$scriptpath"
        test -x "$scriptpath" || die "Could not make $scriptpath executable"

        bold "Root access is required in order to install the driver"
        # TODO: for some reason, a delay is needed here, otherwise pkexec might not appear!
        sleep 1
        exec pkexec "$scriptpath" ${_PAUSE_ON_EXIT:+-p} "$@"
    fi

    detect_adapter
    bold "Updating your apt sources"
    apt-get update || bold 'Continuing even though `apt-get update` reported failure!'

    install_kernel_headers

    bold "Downloading the driver"
    cd $(mktemp -d)
    wget -nv "https://deb.trendtechcn.com/rtl$_CHIP-dkms.deb" ||
        die "Couldn't download the driver"

    bold "Installing and compiling the driver"
    # Prefer apt, but fall back to dpkg if necessary
    if dpkg --compare-versions $(dpkg-query -W apt | awk '{ print $2 }') gt 1.2
    then
        # We want --no-install-recommends here because dkms in Debian
        # recommends a lot of kernel header packages that we may not require.
        # Caution, linuxmint uses a wrapper that can run `apt install --yes`
        # but it doesn't understand `apt --yes install`. Meh.
        apt install --yes --reinstall --no-install-recommends \
            "./rtl$_CHIP-dkms.deb"
    else
        # The downside of using dpkg instead of apt is that dkms etc
        # will be marked as "manually installed".
        apt-get install --yes --no-install-recommends \
            dkms linux-libc-dev libc6-dev &&
            dpkg -i "./rtl$_CHIP-dkms.deb"
    fi

    ret=$?
    printf "\n"
    if [ "$ret" = "0" ]; then
        modprobe "$_CHIP"
        bold "
========================================
 The driver was successfully installed!
========================================"
    else
        request_info
    fi
    pause_exit "$ret"
}

main "$@"
