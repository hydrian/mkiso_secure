# mkiso_secure
Makes a verified ISO image of an optical disk

This is a optical drive ISO ripping script that prioritizes accuracy over performance.

## Installation

Install required executable dependencies. Package names may vary from distribution to distribution.
* cdrdao
* xorriso
* md5sum
* isoinfo
 

1. Download the mkiso_secure.sh file. 
1. Place the mkiso_secure.sh file in one of your directories that is in your $PATH. (i.e. /usr/local/bin)
1. Give the script executable permissions
  - `chmod +x mkiso_secure.sh`
  
## Configuration

System level configuration file is located in `/etc/mkiso_secure.conf`.

User level configuration file is located in `${HOME}/.local/mkiso_secure.conf`. Since this configuration is often machine specific, the config goes here. 

### Valid Directives
Format is in the form of shell variables.

i.e. DRIVE=/dev/cdrom

**DRIVE**

DRIVE is the device file for your optical driver. This defaults to `/dev/cdrom` if it not set.

## Usage

`mkiso_secure.sh OUTPUT_FILENAME`