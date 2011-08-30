#!/bin/sh
# Default acpi script that takes an entry for all actions

# NOTE: This is a 2.6-centric script.  If you use 2.4.x, you'll have to
#       modify it to not use /sys

# including the bashrc.local file for the vlock alias and function,
# but should change to a dedicated vlock script

# get current x user and environment
PID=`pgrep startx`
USER=`ps -o user --no-headers $PID`
USERHOME=`getent passwd $USER | cut -d: -f6`
export XAUTHORITY="$USERHOME/.Xauthority"
for x in /tmp/.X11-unix/*; do
    displaynum=`echo $x | sed s#/tmp/.X11-unix/X##`
    if [ x"$XAUTHORITY" != x"" ]; then
        export DISPLAY=":$displaynum"
    fi
done

#minspeed=`cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq`
#maxspeed=`cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq`
#setspeed="/sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed"

set $*

logger $1
logger $4

case "$1" in
    ibm/hotkey)
	case "$4" in
		0000101b)
                        logger "ACPI: Microphone Mute HotKey Pressed"
                        # currently testing handling this in xbindkeys
                        #/usr/bin/amixer sset Capture toggle
		;;
		00001002)
                        logger "ACPI: Lock HotKey Pressed"
			physlock -d -u $USER &
		;;
		00001003)
                        logger "ACPI: Battery HotKey Pressed"
                        if [ "`cat /var/run/pm-utils/pm-powersave/state`" = "true" ]
			then
				logger "ACPI: setting powersave to false"
        			/usr/sbin/pm-powersave false &
			else
				logger "ACPI: setting powersave to true"
        			/usr/sbin/pm-powersave true &
			fi  
		;;
		00001004)
                        logger "ACPI: Sleep HotKey pressed"
			/usr/sbin/pm-suspend &
		;;
		00001005)
                        logger "ACPI: Wireless power toggled (BIOS should rfkill, ACPI will trigger netcfg)"
                        #if [ "`cat /sys/class/rfkill/rfkill1/state`" = "0" ]
			if iwconfig wlan0 | grep -q "Tx-Power=off" 
			then
				logger "ACPI Event: Wireless adapter is powered off; suspending netcfg connections"
				sudo netcfg all-suspend -i wlan0 &
			else
				logger "ACPI Event: Wireless adapter is powered up"
				lastprofile_path=/var/run/network/last_profile
				if [ -f "$lastprofile_path" ]; then
					logger "ACPI Event: Attempting to reconnect to network profile `cat $lastprofile_path`"
					sudo netcfg `cat $lastprofile_path` -i wlan0 &
				else
					logger "ACPI Event: attempting automatic resume"
					sudo netcfg all-resume -i wlan0 &
				fi
			fi
		;;
		00001006)
                        logger "ACPI: Camera HotKey Pressed"
			setterm -blank poke &
			#command here
		;;
		00001008)
                        logger "ACPI: Trackpad HotKey Pressed"
			export DISPLAY=:0.0
			xinput set-int-prop 'SynPS/2 Synaptics TouchPad' 'Device Enabled' 8 `xinput list-props 12 | grep -i enabled | awk '{ if ($4==0) print 1; else print 0}'` &
		;;
		00001009)
                        logger "ACPI: Bluetooth power toggled"
			#if [ "`cat /sys/class/rfkill/rfkill0/state`" = "0" ]
			if rfkill list bluetooth | grep -iq "Soft blocked: yes"
			then
				logger "ACPI: Bluetooth powering on."
				rfkill unblock bluetooth &
			else
				logger "ACPI: Bluetooth powering off."
				rfkill block bluetooth &
			fi
		;;
		0000100c)
                        logger "ACPI: Hibernate HotKey Pressed"
			/usr/sbin/pm-hibernate &
		;;
		00001014)
                        logger "ACPI: Zoom HotKey Pressed"
			#physlock -d -u $USER &
		;;
		00005009)
                        logger "ACPI: Display moved to tablet orientation"
			#/usr/local/bin/rotate-screen &
		;;
		0000500a)
                        logger "ACPI: Display moved to laptop orientation"
			/usr/local/bin/rotate-screen --normal &
		;;
	esac
	;;
    button/power)
        #echo "PowerButton pressed!">/dev/tty5
        case "$2" in
            PWRF)
		tabletpath=/sys/devices/platform/thinkpad_acpi/hotkey_tablet_mode
		if [ -f "$tabletpath" ]; then
			tabletmode="`cat $tabletpath`" 
		else
			tabletmode=0
		fi
		case "$tabletmode" in
			0)
				#laptop mode; poweroff
				logger "ACPI: PowerButton pressed: $2"
				logger "ACPI: Laptop Mode detected; shutting down"
				# switch to full power as there seems to be a (possibly-cpu freq related) bug
				# that prevents proper shutdown otherwise
				/usr/sbin/pm-powersave false &
				/sbin/poweroff &
			;;
			1)
				logger "ACPI: PowerButton pressed: $2"
				logger "ACPI: Tablet Mode detected; toggling powersave mode"
				#tablet mode; powersavings toggle
				#TODO: this should be a function
				if [ "`cat /var/run/pm-utils/pm-powersave/state`" = "true" ]
				then
					logger "ACPI: setting powersave to false"
					/usr/sbin/pm-powersave false &
				else
					logger "ACPI: setting powersave to true"
					/usr/sbin/pm-powersave true &
				fi  
			;;
		esac
	    ;;
        esac
        ;;
    button/sleep)
        case "$2" in
            SLPB)   echo -n mem >/sys/power/state ;;
            *)      logger "ACPI action undefined: $2" ;;
        esac
        ;;
    ac_adapter)
        case "$2" in
            AC)
                case "$4" in
                    00000000)
			beep
			logger "ACPI: AC Adapter unplugged"
			logger "ACPI: setting powersave to true"
			/usr/sbin/pm-powersave true &
                        #echo -n $minspeed >$setspeed
                        #/etc/laptop-mode/laptop-mode start
                    ;;
                    00000001)
			beep
			logger "ACPI: AC Adapter plugged in"
			logger "ACPI: setting powersave to false"
			/usr/sbin/pm-powersave false &
                        #echo -n $maxspeed >$setspeed
                        #/etc/laptop-mode/laptop-mode stop
                    ;;
                esac
                ;;
            *)  logger "ACPI action undefined: $2" ;;
        esac
        ;;
    battery)
        case "$2" in
            BAT1)
                case "$4" in
                    00000000)   
			#echo "offline" >/dev/tty5
                    ;;
                    00000001)
			#echo "online"  >/dev/tty5
                    ;;
                esac
                ;;
            CPU0)	
                ;;
            *)  logger "ACPI action undefined: $2" ;;
        esac
        ;;
    button/lid)
        #echo "LID switched!">/dev/tty5
	if grep -q closed /proc/acpi/button/lid/LID/state
	then
	# lid has just been closed
		# this is where we could suspend networks, but pm-suspend might do it for us
		# and perhaps I should just put those scripts there instead...
		logger "ACPI EVENT: Lid closed"
		/usr/sbin/pm-suspend &
	else
	# lid has just been opened
	# check ac adapter plug in state, if unplugged then start pm-powersave
	# as it's common to close lid and then unplug machine
	# UPDATE: now handling this in /etc/pm/sleep.d/00powersave
		logger "ACPI EVENT: Lid opened"
		#if grep -q 0 /sys/class/power_supply/ACAD/online
		#then
			## unplugged
			#logger "ACPI EVENT: Lid opened with AC unplugged, entering power-saving mode"
			#/usr/sbin/pm-powersave true
		#else
			## plugged in
			#logger "ACPI EVENT: Lid opened with AC plugged, entering full-power mode"
			#/usr/sbin/pm-powersave false
		#fi
	fi
        ;;
    *)
        logger "ACPI group/action undefined: $1 / $2"
        ;;
esac
