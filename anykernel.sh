# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Nebula For OnePlus 6/6T by Eliminater74 @ xda-developers
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=OnePlus6
device.name2=OnePlus6T
device.name3=
device.name4=
device.name5=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chmod -R 755 $ramdisk/sbin;
chown -R root:root $ramdisk/*;


## AnyKernel install
dump_boot;

# Add skip_override parameter to cmdline so user doesn't have to reflash Magisk
if [ -d $ramdisk/.subackup -o -d $ramdisk/.backup ]; then
  ui_print " "; ui_print "Magisk detected! Patching cmdline so reflashing Magisk is not necessary...";
  patch_cmdline "skip_override" "skip_override";
else
  patch_cmdline "skip_override" "";
fi;

# begin ramdisk changes
# end ramdisk changes

# Install the boot image
write_boot;

## end install

