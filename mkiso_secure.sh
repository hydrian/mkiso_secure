#!/usr/bin/env bash

DEFAULT_DRIVE='/dev/cdrom'
EJECT_WHEN_DONE_DEFAULT=false
TMP_DIR_DEFAULT='/tmp'

USE_MIN_SPEED=true
OUTPUT_ISO_FILE="${1}"
SYSTEM_CONFIG_FILE='/etc/mkiso_secure.conf'
USER_CONFIG_FILE="${HOME}/.local/mkiso_secure.conf"
#Loading Configuration

if [ -e "$SYSTEM_CONFIG_FILE" ] ; then
	. "$SYSTEM_CONFIG_FILE"
fi

if [ -e "${USER_CONFIG_FILE}" ] ; then
	. "${USER_CONFIG_FILE}"
fi
DRIVE="${DRIVE:-$DEFAULT_DRIVE}"
EJECT_WHEN_DONE="${EJECT_WHEN_DONE:-$EJECT_WHEN_DONE_DEFAULT}"
TMP_DIR="${TMP_DIR:-$TMP_DIR_DEFAULT}"

### Checking input ###
if [ -e "${DRIVE}" ] ; then
	if [ ! -r "${DRIVE}" ] ; then
		echo "This user does not have premissions to read directly from $DRIVE" 1>&2
		exit 2
	fi
else 
	echo "${DRIVE} drive file does not exist" 1>&2
	exit 2
fi

if [ -z "${OUTPUT_ISO_FILE}" ] ; then
	echo "Please provide an output file argument" 1>&2
	exit 2
fi

if [ -e "${OUTPUT_ISO_FILE}" ] ; then
	echo "An file exists with the OUTPUT_ISO_FILE name." 1>&2
	echo "Please delete existing file or change OUTPUT_ISO_FILE filename" 1>&2
	exit 2
fi


blockdev --getsize 64 ${DRIVE} 2>&1|grep -i 'No Medium found' -q
if [ $? -eq 0 ] ; then
	echo "No disc in drive. Please insert disc." 1>&2
	exit 2
fi

echo "Detecting drive/media read speed"
if ($USE_MIN_SPEED) ; then
	READ_SPEED=$(xorriso -outdev "${DRIVE}" -list_speeds 2>/dev/null|grep 'Read speed'|sed -r 's/.*,[[:space:]]+([[:digit:]]+)\..*/\1/'|sort -n|uniq|head -n1)
else 
	READ_SPEED=$(xorriso -outdev "${DRIVE}" -list_speeds 2>/dev/null|grep 'Read speed'|sed -r 's/.*,[[:space:]]+([[:digit:]]+)\..*/\1/'|sort -n|uniq|tail -n1)
fi
echo "Detected ${READ_SPEED}x read speed"
echo "Slowing cdrom read speed to ${READ_SPEED}x for best quality"
eject -x ${READ_SPEED} ${DRIVE}
if [ $? -ne 0 ] ; then
	echo "Failed to set optical drive read speed" 1>&2
	exit 2
fi

echo "Detecting if disc has multiple sessions"
SESSION_NUMBER=$(cdrdao disk-info --device "${DRIVE}" 2>/dev/null|grep 'Sessions'|sed -r 's/.*\:\ ([[:digit:]]+).*/\1/')
if [ ${SESSION_NUMBER} -ne 1 ] ; then
	echo "There are ${SESSION_NUMBER} sessions on this disc." 1>&2
	echo "If this disc has more than 1 session, you need to use a bin/cue copy program." 1>&2
	exit 2
fi

echo "Generating checksums for original disc."
echo "This may take a while"
echo "Generating first checksum"
DISC_MD5_1=$(md5sum "$DRIVE")
echo "Generating second checksum"
DISC_MD5_2=$(md5sum "$DRIVE")

if [ "${DISC_MD5_1}" != "${DISC_MD5_2}" ] ; then
	echo "Could not get consistent checksum from the original disc." 1>&2
	echo "Please clean / resurface disk and try again." 1>&2
	exit 2
fi

WORK_DIR=$(mktemp -d --tmpdir="${TMP_DIR}")
echo "Ripping ISO image from disc"
DISC_INFO=$(isoinfo -d -i "${DRIVE}" | grep -i -E 'block size|volume size')
BLOCK_SIZE=$(echo "$DISC_INFO"|grep 'Logical block size'|sed -r 's/.*\:\ ([[:digit:]]+).*/\1/')
VOL_SIZE=$(echo "$DISC_INFO"|grep 'Volume size'|sed -r 's/.*\:\ ([[:digit:]]+).*/\1/')
dd if="${DRIVE}" of="${WORK_DIR}/image.iso" bs=${BLOCK_SIZE} count=${VOL_SIZE} status=progress
if [ $? -eq 0 ] ; then
	echo "Disc rip complete."
else 
	echo "Ripping disc failed" 1>&2
	rm -Rf "${WORK_DIR}"
	exit 2
fi

echo "Verifing ripped copy to original"
ISO_MD5=$(md5sum "${WORK_DIR}/image.iso")

DISC_MD5_1_CLEAN=$(echo "${DISC_MD5_1}"|cut -f1 -d \ )
ISO_MD5_CLEAN=$(echo "${ISO_MD5}"|cut -f1 -d \ )
	
if [ "${DISC_MD5_1_CLEAN}" == "${ISO_MD5_CLEAN}" ] ; then
	echo "ISO verification successful."
else
	echo "ISO image checksum failed" 1>&2
	echo "ISO is an unreliable copy." 1>&2
	rm -Rf "${WORK_DIR}" 
	exit 2
fi

cp "${WORK_DIR}/image.iso" "${OUTPUT_ISO_FILE}"
if [ $? -eq 0 ] ; then
	echo "ISO rip completed successfully."
else 
	echo "Failed to copy ISO image to ${OUTPUT_ISO_FILE}" 1>&2
	rm -Rf "${WORK_DIR}"
	exit 2
fi

if ($EJECT_WHEN_DONE) ; then
	echo "Ejecting media"
	eject "${DRIVE}"
fi
rm -Rf "${WORK_DIR}"
exit 0