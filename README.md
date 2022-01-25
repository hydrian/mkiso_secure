# mkiso_secure
Makes a verified ISO image of an optical disk

This is an optical drive ISO ripping script that prioritizes accuracy over performance. This means, the optical drive is run at its slowest possible read speed to minimize read errors. This is important for discs that have visual imperfection on the media. mkiso_secure.sh also reads the media three times. This is to get a reliable checksum to compare against after the ISO file is ripped.

The script also does common detections for types of media format type that ISOs are not suited like multi-session discs.

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

DRIVE (string) is the device file for your optical driver. This defaults to `/dev/cdrom` if it not set.

**EJECT_WHEN_DONE**

EJECT_WHEN_DONE (true/false) Opens the optical drive when done. Defaults to false.

## Usage

`mkiso_secure.sh OUTPUT_FILENAME`