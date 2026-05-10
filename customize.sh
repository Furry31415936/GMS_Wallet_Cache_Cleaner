# This script will be executed in post-fs-data mode during boot
# More info in the main Magisk thread

# You can use this script to perform actions before the system and vendor partitions are mounted as read-only

# Do NOT assume where your module will be installed.
# The absolute path of your module directory is held by $MODPATH
# This will allow your module to be installed to either /magisk or /adb/modules

# The following properties will be set
# $MODPATH/mysub/.../file will be installed to /mysub/.../file
# $MODPATH/system/.../file will be installed to /system/.../file
# $MODPATH/vendor/.../file will be installed to /vendor/.../file
# $MODPATH/product/.../file will be installed to /product/.../file
# $MODPATH/system_ext/.../file will be installed to /system_ext/.../file
# $MODPATH/odm/.../file will be installed to /odm/.../file
# $MODPATH/oem/.../file will be installed to /oem/.../file
# $MODPATH/data/.../file will be installed to /data/.../file
# $MODPATH/sdcard/.../file will be installed to /sdcard/.../file

# This function will be called after installation is done
# You can use it to do cleaning, hide stuff from Magisk Manager, etc.
post_install() {
  # Create backup directory if it doesn't exist
  mkdir -p /data/adb/gms_backup
  chmod 755 /data/adb/gms_backup
  # Set proper permissions for the script files
  chmod 755 $MODPATH/clear.sh
  chmod 755 $MODPATH/service.sh
}

# This function will be called when the module is disabled
# You can use it to revert changes made in post_install()
# You should not delete files in post_install() since that will break the squashfs
disable() {
  # Nothing to do here
}

# This function will be called when the module is removed
# You should not use this as a replacement for the disable hook
# Neither should you put actual removals in post_install() since that will break the squashfs
uninstall() {
  # Nothing to do here - Magisk will handle file removal
}