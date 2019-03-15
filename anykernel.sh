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
device.name3=OnePlus6TSingle
device.name4=
device.name5=
supported.versions=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


# Save the users from themselves
android_version="$(file_getprop /system/build.prop "ro.build.version.release")";
supported_version=9;
if [ "$android_version" != "$supported_version" ]; then
  ui_print " "; ui_print "You are on $android_version but this kernel is only for $supported_version!";
  exit 1;
fi;

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chown -R root:root $ramdisk/*;


## AnyKernel install
dump_boot;

# Add skip_override parameter to cmdline so user doesn't have to reflash Magisk
if [ -d $ramdisk/.subackup -o -d $ramdisk/.backup ]; then
  ui_print " "; ui_print "Magisk detected! Patching cmdline so reflashing Magisk is not necessary...";
  patch_cmdline "skip_override" "skip_override";
else
  ui_print " "; ui_print "Magisk NOT DETECTED: Please Install Magisk to gain full use of kernel..";
  patch_cmdline "skip_override" "";
fi;

# detect OS edition
userflavor="$(grep "^ro.build.user" /system/build.prop | cut -d= -f2):$(grep "^ro.build.flavor" /system/build.prop | cut -d= -f2)";
case "$userflavor" in
  "OnePlus:OnePlus6T-user")
    os="oos";
    os_string="OxygenOS"
    ;;
  "OnePlus:OnePlus6-user")
    os="oos";
    os_string="OxygenOS"
    ;;
  "OnePlus:OnePlus6TSingle-user")
    os="oos";
    os_string="OxygenOS"
    ;;
  *)
    os="custom";
    os_string="a custom ROM"
    ;;
esac;

# Tell user what was detected and what works and or not works
if [ "$os_string" = "a custom ROM" ]; then
   ui_print " "; ui_print "-> $os_string detected, Most things will work, But Some things Wont, But we are working on that..";
   else
   ui_print " "; ui_print "-> $os_string detected, Everything should work on Stock..";
fi;

# Clean up Other Kernels Overlays that could conflict with ours:
rm -rf $ramdisk/overlay;

# begin ramdisk changes
# end ramdisk changes

# Install the boot image
write_boot;

## end install

