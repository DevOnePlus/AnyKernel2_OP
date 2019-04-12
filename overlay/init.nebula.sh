#!/system/bin/sh
# Nebula Kernel init helper script
sleep 20;

# Helpers
little_max() { echo $1 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq; }
big_max() { echo $1 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq; }
little_min() { echo $1 > /sys/module/cpu_input_boost/parameters/remove_input_boost_freq_lp; }
big_min() { echo $1 > /sys/module/cpu_input_boost/parameters/remove_input_boost_freq_perf; }
little_boost() { echo $1 > /sys/module/cpu_input_boost/parameters/input_boost_freq_lp; }
big_boost() { echo $1 > /sys/module/cpu_input_boost/parameters/input_boost_freq_hp; }
little_gov_param() { echo $2 > /sys/devices/system/cpu/cpu0/cpufreq/$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)/$1; }
big_gov_param() { echo $2 > /sys/devices/system/cpu/cpu4/cpufreq/$(cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor)/$1; }
gov_param() { little_gov_param $1 $2; big_gov_param $1 $2; }
boost_duration() { echo $1 > /sys/module/cpu_input_boost/parameters/input_boost_duration; }
boost_timeout() { echo $1 > /sys/module/cpu_input_boost/parameters/frame_boost_timeout; }
stune_boost() { echo $1 > /sys/module/cpu_input_boost/parameters/dynamic_stune_boost; }
gpu_min() { echo $1 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq; }

# Tune Core_CTL for proper task placement
	echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable
	echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/enable

# Disable CAF task placement for Big Cores
	echo 0 > /proc/sys/kernel/sched_walt_rotate_big_tasks

# Set default schedTune value for foreground/top-app
#	echo 1 > /dev/stune/top-app/schedtune.boost

# Setup Schedutil Governor
	echo "schedutil" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
	echo 500 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us
	echo 20000 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/down_rate_limit_us
	echo 1 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/iowait_boost_enable
	echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/pl
	echo 0 > /sys/devices/system/cpu/cpufreq/policy0/schedutil/hispeed_freq

	echo "schedutil" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor	
	echo 500 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/up_rate_limit_us
	echo 20000 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/down_rate_limit_us
	echo 1 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/iowait_boost_enable
	echo 0 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/pl
	echo 0 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/hispeed_freq

# Input boost and stune configuration
	echo "0:1056000 1:0 2:0 3:0 4:1056000 5:0 6:0 7:0" > /sys/module/cpu_boost/parameters/input_boost_freq
	echo 500 > /sys/module/cpu_boost/parameters/input_boost_ms
#	echo 50 > /sys/module/cpu_boost/parameters/dynamic_stune_boost
#	echo 1500 > /sys/module/cpu_boost/parameters/dynamic_stune_boost_ms

# Dynamic Stune Boost during sched_boost
#	echo 50 > /dev/stune/top-app/schedtune.sched_boost

# Setup EAS cpusets values for better load balancing
	echo 0-7 > /dev/cpuset/top-app/cpus
	# Since we are not using core rotator, lets load balance
	echo 0-3,6-7 > /dev/cpuset/foreground/cpus
	echo 0-1 > /dev/cpuset/background/cpus
	echo 0-3  > /dev/cpuset/system-background/cpus

# For better screen off idle
	echo 0-3 > /dev/cpuset/restricted/cpus

# Adjust Read Ahead
	echo 128 > /sys/block/sda/queue/read_ahead_kb
	echo 128 > /sys/block/dm-0/queue/read_ahead_kb

# Actions
case "$1" in
### USB Functions ###
	'usb_msc')
		rm -f /config/usb_gadget/g1/configs/b.1/function0
		ln -s /config/usb_gadget/g1/functions/mass_storage.0 /config/usb_gadget/g1/configs/b.1/function0
		echo msc > /config/usb_gadget/g1/configs/b.1/strings/0x409/configuration
		echo $(getprop sys.usb.controller) > /config/usb_gadget/g1/UDC
		setprop sys.usb.state $(getprop sys.usb.config)
		;;
### Profiles ###
	'battery')
		# CPU: Little
		little_min 300000
		little_max 1516800
		little_boost 748800
		little_gov_param hispeed_freq 0
		# CPU: Big
		big_max 1209600
		big_boost 0
		big_gov_param hispeed_freq 0
		# CPU: Governor
		gov_param hispeed_load 100
		gov_param iowait_boost_enable 0
		gov_param up_rate_limit_us 10000
		gov_param down_rate_limit_us 12000
		# CPU: Boost
		stune_boost 10
		boost_duration 32
		boost_timeout 1750

		# GPU
		gpu_min 180000000
		gpu_gov msm-adreno-tz
		;;
	'balanced')
		# CPU: Little
		little_min 576000
		little_max 1766400
		little_boost 1056000
		little_gov_param hispeed_freq 0
		# CPU: Big
		big_max 2323200
		big_boost 902400
		big_gov_param hispeed_freq 0
		# CPU: Governor
		gov_param hispeed_load 90
		gov_param iowait_boost_enable 1
		gov_param up_rate_limit_us 10000
		gov_param down_rate_limit_us 20000
		# CPU: Boost
		stune_boost 15
		boost_duration 64
		boost_timeout 3250

		# GPU
		gpu_min 180000000
		gpu_gov msm-adreno-tz
		;;
	'performance')
		# CPU: Little
		little_min 748800
		little_max 1766400
		little_boost 1516800
		little_gov_param hispeed_freq 1228800
		# CPU: Big
		big_max 2803200
		big_boost 1363200
		big_gov_param hispeed_freq 1363200
		# CPU: Governor
		gov_param hispeed_load 15
		gov_param iowait_boost_enable 1
		gov_param up_rate_limit_us 10000
		gov_param down_rate_limit_us 25000
		# CPU: Boost
		stune_boost 15
		boost_duration 125
		boost_timeout 15000

		# GPU
		gpu_min 342000000
		gpu_gov msm-adreno-tz
		;;
	'turbo')
		# CPU: Little
		little_min 748800
		little_max 1766400
		little_boost 1516800
		little_gov_param hispeed_freq 1228800
		# CPU: Big
		big_max 2803200
		big_boost 1363200
		big_gov_param hispeed_freq 1363200
		# CPU: Governor
		gov_param hispeed_load 15
		gov_param iowait_boost_enable 1
		gov_param up_rate_limit_us 400
		gov_param down_rate_limit_us 25000
		# CPU: Boost
		stune_boost 15
		boost_duration 125
		boost_timeout 30000

		# GPU
		gpu_min 342000000
		gpu_gov msm-adreno-tz
		;;
	*)
		echo "Valid actions: [usb] usb_msc, [profiles] battery, balanced, performance, turbo"
		exit 1
esac
