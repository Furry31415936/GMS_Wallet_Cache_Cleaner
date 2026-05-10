#!/system/bin/sh
##########################################################################################
#
# Magisk Module Installer Script
#
##########################################################################################

##########################################################################################
# Defines
##########################################################################################

# NOTE: This part has to be adjusted to fit your module

# This will be the folder name that is created inside /data/adb/modules
# This should match the id in module.prop
MODID=gms_wallet_cache_cleaner

# Set to true if you do *NOT* want Magisk to mount any files for you. Most modules do not need this.
SKIPMOUNT=false
# Set to true if you need to load system.prop
PROPFILE=false
# Set to true if you need post-fs-data script (Most modules don't)
POSTFSDATA=false
# Set to true if you need late_start service script (Most modules don't)
LATESTARTSERVICE=false

##########################################################################################
# Installation Message
##########################################################################################

# Set what you want to show when installing your module

print_modname() {
  ui_print "*******************************"
  ui_print "   GMS Wallet Cache Cleaner    "
  ui_print "*******************************"
}

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# By default Magisk will merge your files with the original system
# Directories listed here however, will be directly mounted to the correspond directory in the system

# Construct your list in the following format
# This is an example
REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here
REPLACE="
"

##########################################################################################
# Permissions
##########################################################################################

set_permissions() {
  # The following is default permissions, DO NOT remove
  set_perm_recursive  $MODPATH  0  0  0755  0644  u:object_r:system_file:s0
  set_perm  $MODPATH/clear.sh  0  0  0755  u:object_r:system_file:s0
  set_perm  $MODPATH/service.sh  0  0  0755  u:object_r:system_file:s0
  
  # Set permissions for webroot directory
  set_perm_recursive  $MODPATH/webroot  0  0  0755  0644  u:object_r:system_file:s0
}

##########################################################################################
# Custom Functions
##########################################################################################

# This file (config.sh) contains all the basic information about your module
# Custom scripts should be in the 'service.d', 'post-fs-data.d', 'sepolicy.rule' and 'post-mount.d' directory
# And please make sure to fill up the description in 'module.prop'

# Custom functions
# This is where you can define custom functions that can be called from 'customize.sh'

# Create backup directory
create_backup_dir() {
  mkdir -p /data/adb/gms_backup
  chmod 755 /data/adb/gms_backup
}