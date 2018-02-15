#!/sbin/sh
# ------------------------------
# TGPKERNEL INSTALLER 6.0.9
# Created by @djb77
#
# Credit also goes to @Tkkg1994,
# @lyapota, @Morogoku, 
# @dwander for code and/or ideas
# ------------------------------

# Read option number from updater-script
OPTION=$1

# Block location
BLOCK=/dev/block/platform/11120000.ufs/by-name

# Variables
TGPTEMP=/tmp/tgptemp
AROMA=/tmp/aroma
TGP=/data/media/0/TGPKernel
CONFIG=$TGP/config
BUILDPROP=/system/build.prop
PROPDEFAULT=/system/etc/prop.default
VENDORBUILDPROP=/vendor/build.prop
KERNEL_REMOVE="init.services.rc init.PRIME-Kernel.rc init.spectrum.sh init.spectrum.rc init.primal.rc init.noto.rc kernelinit.sh wakelock.sh super.sh cortexbrain-tune.sh spectrum.sh kernelinit.sh spa init_d.sh initd.sh moro-init.sh sysinit.sh tgpkernel.sh noto.sh"

if [ $OPTION == "setup" ]; then
	## Set Permissions
	chmod 755 $AROMA/adb
	chmod 755 $AROMA/adb.bin
	chmod 755 $AROMA/fastboot
	chmod 755 $AROMA/busybox
	chmod 755 $AROMA/tar
	chmod 755 $AROMA/tgpkernel.sh
	exit 10
fi

if [ $OPTION == "config_check" ]; then
	## Config Check
	# If config backup is present, alert installer
	mount $BLOCK/USERDATA /data
	if [ -e $CONFIG/tgpkernel-backup.prop ]; then
		echo "install=1" > $AROMA/backup.prop
	fi
	exit 10
fi


if [ $OPTION == "check_g960x" ]; then
	echo "install=1" > $AROMA/g960x.prop
	exit 10
fi

if [ $OPTION == "check_g965x" ]; then
	echo "install=1" > $AROMA/g965x.prop
	exit 10
fi

if [ $OPTION == "rom_check" ]; then
	## ROM Check
	# Check for Deodexed ROMs
	if [ ! -d /system/framework/arm64 ]; then
		echo "install=1" > $AROMA/deodexed.prop
	fi
	# Set for S9 ROMs
	if grep -q ro.build.product=star $BUILDPROP; then
		echo "install=1" > $AROMA/check_s9.prop
	fi
	# Set for S9+ ROMs
	if grep -q ro.build.product=star2 $BUILDPROP; then
		echo "install=0" > $AROMA/check_s9.prop
		echo "install=1" > $AROMA/check_s9+.prop
	fi
	exit 10
fi

if [ $OPTION == "config_backup" ]; then
	## Backup Config
	# Check if TGP folder exists on Internal Memory, if not, it is created
	if [ ! -d $TGP ]; then
		mkdir $TGP
		chmod 777 $TGP
	fi
	# Check if config folder exists, if it does, delete it 
	if [ -d $CONFIG-backup ]; then
		rm -rf $CONFIG-backup
	fi
	# Check if config folder exists, if it does, ranme to backup
	if [ -d $CONFIG ]; then
		mv -f $CONFIG $CONFIG-backup
	fi
	# Check if config folder exists, if not, it is created
	if [ ! -d $CONFIG ]; then
		mkdir $CONFIG
		chmod 777 $CONFIG
	fi
	# Copy files from $AROMA to backup location
	cp -f $AROMA/* $CONFIG
	# Delete any files from backup that are not .prop files
	find $CONFIG -type f ! -iname "*.prop" -delete
	# Remove unwanted .prop files from the backup
	cd $CONFIG
	[ -f "$CONFIG/check_s9.prop" ] && rm -f $CONFIG/check_s9.prop
	[ -f "$CONFIG/check_s9+.prop" ] && rm -f $CONFIG/check_s9+.prop
	[ -f "$CONFIG/deodexed.prop" ] && rm -f $CONFIG/deodexed.prop
	[ -f "$CONFIG/g960x.prop" ] && rm -f $CONFIG/g960x.prop
	[ -f "$CONFIG/g965x.prop" ] && rm -f $CONFIG/g965x.prop
	for delete_prop in *.prop 
	do
		if grep "item" "$delete_prop"; then
			rm -f $delete_prop
		fi
		if grep "install=0" "$delete_prop"; then
			rm -f $delete_prop
		fi 
	done
	exit 10
fi

if [ $OPTION == "config_restore" ]; then
	## Restore Config
	# Copy backed up config files to $AROMA
	cp -f $CONFIG/* $AROMA
	exit 10
fi

if [ $OPTION == "wipe_magisk" ]; then
	## Wipe old Magisk / SuperSU Installs (@mwilky)
	mount /cache
	rm -rf /system/.pin /system/bin/.ext /system/etc/.installed_su_daemon /system/etc/.has_su_daemon \
	/system/xbin/daemonsu /system/xbin/su /system/xbin/sugote /system/xbin/sugote-mksh /system/xbin/supolicy \
	/system/bin/app_process_init /system/bin/su /cache/su /system/lib/libsupol.so /system/lib64/libsupol.so \
	/system/su.d /system/etc/install-recovery.sh /system/etc/init.d/99SuperSUDaemon /cache/install-recovery.sh \
	/system/.supersu /cache/.supersu /data/.supersu \
	/system/app/Superuser.apk /system/app/SuperSU /cache/Superuser.apk \
	/cache/.supersu /cache/su.img /cache/SuperSU.apk \
	/data/.supersu /data/stock_boot_*.img.gz /data/su.img \
	/data/SuperSU.apk /data/app/eu.chainfire.supersu* \
	/data/data/eu.chainfire.supersu /data/supersu /supersu  2>/dev/null
	exit 10
fi

if [ $OPTION == "system_patch" ]; then
	## System Patches
	# Patch prop.default
	sed -i '/ro.debuggable/a nro.security.vaultkeeper.feature=0\nwlan.wfd.hdcp=disable\nro.securestorage.support=false' $PROPDEFAULT
	# Remove RMM State Lock
	rm -rf /system/priv-app/Rlc
	# Remove Security Log Agent
	rm -rf /system/app/SecurityLogAgent
	# Remove init.d and addon.d Placeholders
	rm -f /system/addon.d/placeholder
	rm -f /system/etc/init.d/placeholder
	# Delete Wakelock.sh 
	rm -f /magisk/phh/su.d/wakelock*
	rm -f /su/su.d/wakelock*
	rm -f /system/su.d/wakelock*
	rm -f /system/etc/init.d/wakelock*
	# Fix sepolicy for Deodexed ROMs
	if grep -q install=1 $AROMA/deodexed.prop; then
	sed -i -- 's/(allow zygote dalvikcache_data_file (file (ioctl read write create getattr setattr lock append unlink rename open)))/(allow zygote dalvikcache_data_file (file (ioctl read write create getattr setattr lock append unlink rename open execute)))/g' /system/etc/selinux/plat_sepolicy.cil
	fi
	exit 10
fi

if [ $OPTION == "vendor_patch" ]; then
	## Vendor Patches
	# Remove unwanted file from /vendor/app/mcRegistry
	rm -f /vendor/app/mcRegistry/ffffffffd00000000000000000000062.tlbin
	# build.prop Mods
	sed -i -- 's/ro.security.vaultkeeper.feature=1/ro.security.vaultkeeper.feature=0/g' $VENDORBUILDPROP
	sed -i -- 's/o.knox.enhance.zygote.aslr=1/o.knox.enhance.zygote.aslr=0/g' $VENDORBUILDPROP
	sed -i -- 's/ro.frp.pst=\/dev\/block\/persistent/ro.frp.pst=/g' $VENDORBUILDPROP
	# Fix sepolicy for Deodexed ROMs
	if grep -q install=1 $AROMA/deodexed.prop; then
		echo "(allow zygote_26_0 dalvikcache_data_file_26_0 (file (execute)))" >> /vendor/etc/selinux/nonplat_sepolicy.cil
	fi
	exit 10
fi

if [ $OPTION == "kernel_flash" ]; then
	## Flash Kernel (@dwander)
	# Clean up old kernels
	for i in $KERNEL_REMOVE; do
		if test -f $i; then
			[ -f $1 ] && rm -f $i
			[ -f sbin/$1 ] && rm -f sbin/$i
			sed -i "/$i/d" init.rc 
			sed -i "/$i/d" init.samsungexynos8910.rc 
		fi
		if test -f sbin/$i; then
			[ -f sbin/$1 ] && rm -f sbin/$i
			sed -i "/sbin\/$i/d" init.rc 
			sed -i "/sbin\/$i/d" init.samsungexynos8910.rc 
		fi
	done
	for i in $(ls ./res); do
		test $i != "images" && rm -R ./res/$i
	done
	[ -f /system/bin/uci ] && rm -f /system/bin/uci
	[ -f /system/xbin/uci ] && rm -f /system/xbin/uci
	# Flash new Image
	if grep -q install=1 $AROMA/g960x.prop; then
		$AROMA/busybox dd if=$TGPTEMP/boot-960.img of=$BLOCK/BOOT
	fi
	if grep -q install=1 $AROMA/g965x.prop; then
		$AROMA/busybox dd if=$TGPTEMP/boot-965.img of=$BLOCK/BOOT
	fi
	sync
	exit 10
fi

if [ $OPTION == "splash_flash" ]; then
	## Custom Splash Screen (@Tkkg1994)
	cd /tmp/splash
	mkdir /tmp/splashtmp
	cd /tmp/splashtmp
	$AROMA/tar -xf $BLOCK/UP_PARAM
	cp /tmp/splash/logo.jpg .
	chown root:root *
	chmod 444 logo.jpg
	touch *
	$AROMA/tar -pcvf ../new.tar *
	cd ..
	cat new.tar > $BLOCK/UP_PARAM
	cd /
	rm -rf /tmp/splashtmp
	rm -f /tmp/new.tar
	sync
	exit 10
fi

if [ $OPTION == "adb" ]; then
	## Install ADB
	rm -f /system/xbin/adb /system/xbin/adb.bin /system/xbin/fastboot
	cp -f $AROMA/adb /system/xbin/adb
	cp -f $AROMA/adb.bin /system/xbin/adb.bin
	cp -f $AROMA/fastboot /system/xbin/fastboot
	chown 0:0 "/system/xbin/adb" "/system/xbin/adb.bin" "/system/xbin/fastboot"
	chmod 755 "/system/xbin/adb" "/system/xbin/adb.bin" "/system/xbin/fastboot"
	exit 10
fi

if [ $OPTION == "busybox" ]; then
	## Install Busybox
	rm -f /system/bin/busybox /system/xbin/busybox
	cp -f $AROMA/busybox /system/xbin/busybox
	chmod 755 /system/xbin/busybox
	ln -s /system/xbin/busybox /system/bin/busybox
	/system/xbin/busybox --install -s /system/xbin
	exit 10
fi

