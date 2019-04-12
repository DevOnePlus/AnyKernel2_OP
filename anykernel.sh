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
supported.versions=9
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
ui_print "  • Unpacking image"
dump_boot;

# Clean up Other Kernels Overlays that could conflict with ours:
if [ "$(ls -A $ramdisk/overlay)" ]; then
   ui_print " "; ui_print "-> Detected $ramdisk/overlay Not Empty, Removing Leftovers.. ";
   rm -rf $ramdisk/overlay;
else
   ui_print " "; ui_print "-> Detected $ramdisk/overlay is Empty..";
fi

# Add skip_override parameter to cmdline so user doesn't have to reflash Magisk
if [ -d $ramdisk/.subackup -o -d $ramdisk/.backup ]; then
  ui_print " "; ui_print "* Magisk detected! Patching cmdline so reflashing Magisk is not necessary...";
  patch_cmdline "skip_override" "skip_override";
  chmod +x $TMPDIR/overlay/*.sh
  ui_print " "; ui_print "* Moving, $TMPDIR/overlay/init.nebula.rc,";
  ui_print " "; ui_print "* Moving, $TMPDIR/overlay $ramdisk.";
  mv $TMPDIR/overlay/init.nebula.rc $TMPDIR/overlay/init.$(getprop ro.hardware).rc
  mv $TMPDIR/overlay $ramdisk
else
  patch_cmdline "skip_override" ""
  ui_print '  ! Magisk is not installed; some tweaks will be missing'
fi

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

mountpoint -q /data && {
  # Install custom PowerHAL config
  mkdir -p /data/adb/magisk_simple/vendor/etc
  cp $TMPDIR/powerhint.json /data/adb/magisk_simple/vendor/etc

  # Install second-stage late init script
  mkdir -p /data/adb/service.d
  cp $TMPDIR/95-nebula.sh /data/adb/service.d
  chmod +x /data/adb/service.d/95-nebula.sh

  # Remove old backup DTBOs
	rm -f /data/adb/dtbo_a.orig.img /data/adb/dtbo_b.orig.img

  # Optimize F2FS extension list (@arter97)
  find /sys/fs/f2fs -name extension_list | while read list; do
    if grep -q odex "$list"; then
      echo "Extensions list up-to-date: $list"
      continue
    fi

    echo "Updating extension list: $list"

    echo "Clearing extension list"

    HOT=$(cat $list | grep -n 'hot file extens' | cut -d : -f 1)
    COLD=$(($(cat $list | wc -l) - $HOT))

    COLDLIST=$(head -n$(($HOT - 1)) $list | grep -v ':')
    HOTLIST=$(tail -n$COLD $list)

    echo $COLDLIST | tr ' ' '\n' | while read cold; do
      if [ ! -z $cold ]; then
        echo "[c]!$cold" > $list
      fi
    done

    echo $HOTLIST | tr ' ' '\n' | while read hot; do
      if [ ! -z $hot ]; then
        echo "[h]!$hot" > $list
      fi
    done

    echo "Writing new extension list"

    cat $TMPDIR/f2fs-cold.list | grep -v '#' | while read cold; do
      if [ ! -z $cold ]; then
        echo "[c]$cold" > $list
      fi
    done

    cat $TMPDIR/f2fs-hot.list | while read hot; do
      if [ ! -z $hot ]; then
        echo "[h]$hot" > $list
      fi
    done
  done
} || ui_print '  ! Data is not mounted; some tweaks will be missing'

# begin ramdisk changes
# end ramdisk changes

# Install the boot image
write_boot;

## end install

