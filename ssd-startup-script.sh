#!/usr/bin/env bash

# Set strict error checking
set -emou pipefail
LC_CTYPE=C

# Enable debug output if $DEBUG is set to true
[ "${DEBUG:="false"}" = "true" ] && set -x

# https://cloud.google.com/compute/docs/disks/optimizing-local-ssd-performance
MNT_OPTS="${MNT_OPTS:="defaults,nodelalloc,noatime,discard,nobarrier"}"
MNT_DIR="${MNT_DIR:="/mnt/disks/ssd-array"}"
FS_TYPE="${FS_TYPE:="ext4"}"
MD_DEV="${MD_DEV:="/dev/md9"}"

# Only if device does not exist
if [[ ! -e "${MD_DEV}" ]]; then
  # List all local SSDs
  DEVICES="$(readlink -f /dev/disk/by-id/google-local-ssd-*)"

  # Unmount (local SSDs are mounted by default in GCP)
  for disk in $DEVICES; do
	  if findmnt -rno SOURCE "${disk}" > /dev/null; then
      target="$(findmnt -rno TARGET "${disk}")"
      umount "${disk}"
      rm -rf "${target}"
    fi
	  wipefs --all "${disk}"
  done

  # Create raid0 array
  # shellcheck disable=SC2086
  mdadm --create "${MD_DEV}" --level=0 --raid-devices="$(echo "${DEVICES}" | wc -w)" \
	${DEVICES}
fi

# Make FS
if ! blkid -o value -s TYPE "${MD_DEV}"; then
  "mkfs.${FS_TYPE}" -F "${MD_DEV}"
fi

# Mount
mkdir -p "${MNT_DIR}"
chmod a+w "${MNT_DIR}"

if ! findmnt -rno SOURCE "${MD_DEV}" > /dev/null; then
  mount "${MD_DEV}" -t "${FS_TYPE}" --target "${MNT_DIR}" --options "${MNT_OPTS}"
  echo "UUID=$(blkid -s UUID -o value "${MD_DEV}")" "${MNT_DIR}" "${FS_TYPE}" "${MNT_OPTS}" 0 2 >> /etc/fstab
fi

# Return 0 if we can find mounted device
findmnt -rn --target "${MNT_DIR}"
