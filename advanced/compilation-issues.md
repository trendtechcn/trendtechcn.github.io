---
nav_exclude: true
---

# Compilation issues

The Realtek drivers for our adapters fail to compile in the following distributions. In all cases, the tested architecture was x86_64.

* 8812au, version 5.9.3.37279.20201012
* 88x2bu, version 5.8.7.4.37264.20200922
* 8821cu, version 5.8.1.37266.20200929

| Distribution | Version | Kernel version | 8812au | 88x2bu | 8821cu |
|---|---|---|---|---|---|
| [CentOS Linux](https://www.centos.org) | [8.3](http://ftp.ntua.gr/pub/linux/centos/8.3.2011/isos/x86_64/CentOS-8.3.2011-x86_64-boot.iso) | 4.18.0-240.22.1<br>.el8_3.x86_64 | [make.log](logs/8812au-centos-linux.txt) | [make.log](logs/88x2bu-centos-linux.txt) | [make.log](logs/8821cu-centos-linux.txt) |
| [CentOS Stream](https://www.centos.org/centos-stream) | [8](http://ftp.ntua.gr/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-20210415-boot.iso) | 4.18.0-301.1<br>.el8.x86_64 | [make.log](logs/8812au-centos-stream.txt) | [make.log](logs/88x2bu-centos-stream.txt) | [make.log](logs/8821cu-centos-stream.txt) |
| [openSUSE Leap](https://www.opensuse.org) | [15.3](https://download.opensuse.org/distribution/leap/15.3/live/openSUSE-Leap-15.3-KDE-Live-x86_64-Media.iso) | 5.3.18-55-default | [make.log](logs/8812au-opensuse-leap.txt) | [make.log](logs/88x2bu-opensuse-leap.txt) | [make.log](logs/8821cu-opensuse-leap.txt) |
| [Red Hat Enterprise Linux](https://www.redhat.com) | [8.3](https://access.cdn.redhat.com/content/origin/files/sha256/1b/1b73ebfebd1f9424c806032168873b067259d8b29f4e9d39ae0e4009cce49b93/rhel-8.3-x86_64-boot.iso) | 4.18.0-240.22.1<br>.el8_3.x86_64 | [make.log](logs/8812au-rhel.txt) | [make.log](logs/88x2bu-rhel.txt) | [make.log](logs/8821cu-rhel.txt) |

