figtree
=======

an Arch Linux AIF module to create conFIG TREEs from local or remote profiles
Ethan Schoonover <es@ethanschoonover.com>

## Features

  * Keep your system config in version control. Access locally or remotely (github
    currently supported)

  * Separate hardware specific packages, configuration files,
    and values from other profile scope.

  * Add overlay files and expanded configuration values to AIF installation.

  * Access the profile at install time from the Arch ISO via AIF (automatic procedure)

  * Easily update the profile from a live system; easily update
    a live system from the profile. (partial procedures)

## CODE STATUS: Here there be dragons

Partial procedures related to updating the profile are in progress.
AUR related functions are throwing some filesystem related errors.

## Details

Figtree is an AIF module with several key features:

1. Can be run from a remote path. Boot from a standard Arch Linux installation 
   image and remotely access your custom installation profile with no customization 
   of the ISO.

2. Remote source for both the procedure and profiles can be a version control system.
   Currently only github has been tested, but figtree has been designed to support
   git (github/other), mercurial (bitbucket/other), svn (google-code/other), and wget
   as a fallback option.

3. Intelligent sourcing of files (if you've already specified a remote path for the 
   procedure, you can use a relative path for the profile). Procedures and profiles
   can be local, remote, both, and from different remote locations.

4. Supports automatic AUR package installation (see issues)

5. Loads both remote and local profiles.

6. Profiles can be standard AIF profiles or "figtree profiles" which support 
   more complex system configuration at install time.

7. Profiles can link to other profiles, creating a con**fig tree** of profiles.

8. Profiles can use custom commands to add to:

   * add to the install package list
   * customize system variables in arbitrary config files
   * add overlay files
   * add kernel parameters
   * add custom system commands to be run at the end of the install

## Install & Update Lifecycle: figtree procedures

Figtree is designed to allow rapid installation from existing profiles, and rapid updating of profiles from an existing installation.

### New Install Procedures:

Run from Arch ISO boot:

  * **automatic** (sources local or remote root profile and automatically 
  installs full system) \
  STATUS: working, AUR option (-a) throwing errors

### Existing System Conform Procedures:

These partial procedures are designed to be run on an existing system (*not* 
from the ISO). They ensure your system matches the profiles and can thus be run 
anytime. They can be run in dry-run mode to see what changes would be made 
first.

  * partial-conform-system (install packages/configs on an existing system) \
    STATUS: in testing

### Update procedures:

These update the profile itself, not the system. They can be run in dry-run 
mode (to implement) to find out what would be updated first.

  * partial-update-overlay (update overlay files, possibly selectively, from live system)

  * partial-update-configs (update config values) - not yet implemented

  * partial-update-packages (update or just list package diff) - not yet implemented

## Profiles, Scope, Linking

One of the key motivations behind figtree was to enable the "stacking" of configuration profiles. It is common to have different hardware but similar desktop environments, application sets and user configurations. Thus one might have a configuration tree like this:

    specific-system
      |
      +--systems/manufacturer/model
      |
      +--environments/type/variant
      |
      +--applicatons/category/set
      |
      +--users/you

A desktop and laptop might thus look like this:

    profiles/es/es-laptop               profiles/es/es-desktop
      |                                   |
      +--systems/lenovo/x220              +--systems/generic/pc
      |                                   |
      +--environments/xmonad/es           +--environments/xmonad/es
      |                                   |
      +--applicatons/cli/basics           +--applications/cli/basics
      +--applicatons/cli/media            +--applications/cli/media
      |                                   +--applicatoins/gui/video
      |                                   |
      +--users/es                         +--users/es

Figtree has several "top level" profile categories (systems, environments, applications, peripherals, profiles, filesystems, users) where profiles can live (as files or in subdirectories). Feedback is welcome regarding this structure.

## USAGE: New, Full Installation: Quick Examples

At a basic Arch ISO boot prompt (new install):

REMOTE PROCEDURE & REMOTE PROFILE

    # aif -p partial-configure-network
    # aif -p http://github.com/altercation/figtree/raw/master/procedures/automatic \
          -c profiles/generic

REMOTE PROCEDURE & REMOTE PROFILE (DIFFERENT SOURCE URLS)

**NOTE WELL**: Profile paths shouldn't include the raw/master path elements. It
should work even if they are included, but it's bad practice. The procedure path from
a github repository must include them as AIF uses wget to source the initial file.

    # aif -p partial-configure-network
    # aif -p http://github.com/altercation/figtree/raw/master/procedures/automatic \
          -c http://github.com/USER2/figtree/profiles/my-laptop

REMOTE PROCEDURE & LOCAL PROFILE

    # aif -p partial-configure-network
    # aif -p http://github.com/altercation/figtree/raw/master/procedures/automatic \
          -c ~/aif-profiles/my-custom-laptop

or local profile in /usr/lib/aif/user/figtree/profiles (as long as there is no profile with the same name on remote repo, otherwise use absolute local path)

    # aif -p partial-configure-network
    # aif -p http://github.com/altercation/figtree/raw/master/procedures/automatic \
          -c profiles/my-custom-laptop

LOCAL PROCEDURE & REMOTE PROFILE

    # aif -p partial-configure-network
    # aif -p figtree/automatic \
          -c https://github.com/altercation/figtree/profiles/my-laptop

LOCAL PROCEDURE & LOCAL PROFILE

    # aif -p figtree/automatic -c profiles/my-desktop

LOCAL PROCEDURE & LOCAL PROFILE (can be any figtree profile)

    # aif -p figtree/automatic -c systems/lenovo/x220/profile

## USAGE: Updating overlay in a local profile

Each profile can have an optional overlay directory in the same parent folder. This 
overlay directory acts as a fake root where overlay files are saved and will be installed.
Thus if you have a profile reference by the path:

    systems/lenovo/x220

The "standard" figtree path for that will be (locally)

    /usr/lib/aif/user/figtree/systems/lenovo/x220/profile

The overlay file for /etc/acpi/handler.sh would thus be:

    /usr/lib/aif/user/figtree/systems/lenovo/x220/overlay/etc/acpi/handler.sh

These overlay files can be automatically saved into your profile overlay directory from
your current live system using the figtree partial procedure `partial-update-overlay`.
Examples:

Update all linked profiles, wiping out existing overlay directory:

    # aif -p figtree/partial-update-overlay -c profiles/my-desktop -wf

Update just one profile:

    # aif -p figtree/partial-update-overlay -c systems/lenovo/x220/profile -s

## Command Line Arguments

  * **-c profile/path**  Config Profile (relative, absolute, or remote path)
  * **-r git|hg|svn|wget**  (only git tested to date) Force repo ON. Remote repository type set manually. Not required (figtree will automatically detect the repo type)
  * **-a**  AUR support ON. Packages not in official repos will be sourced from AUR.
  * **-w**  Wipe overlay directory ON. Old overlay directory will be DELETED first. (partial-update-overlay procedure only) 
  * **-f**  Force overwrite ON. *NO* PROMPTS given prior to overwrite events. (partial-update-overlay only)
  * **-n**  No-backups mode ON. *NO* BACKUP FILES created during overwrites.
  * **-s**  Single-profile mode ON. NO LINKED PROFILES will be processed.
  * **-D**  (not implemented yet) Diff mode ON. File diffs will be displayed prior to file overwrites.

## Profile Commands

Figtree can use normal AIF profiles and can add the following figtree specific 
commands:

  * **depend_profile** path/to/profile
  * **packages** packagename aurpackagename \[anotherpackage\]
  * **blacklist** packagename
  * **config set** /path/to/config/file VALUENAME newvalue
  * **config unset** /path/to/config/file VALUENAME
  * **daemons add** @daemon !daemon daemon
  * **daemons remove** daemon anotherdaemon
  * **modules add** modulename anothermodule
  * **modules remove** modulename anothermodule
  * **networks add** network-name work-networkname \[another-network\]
  * **networks remove** network-name
  * **kernel_params** parameter-list-here
  * **coda** 'arbitrary command goes here to be run at end of installation'
  * **overlay** /etc/file.conf /usr/file/name

The above forms are the canonical forms of the commands but for the most part 
the plural/singular forms are identical (packages and package are identical 
commands). This avoids a common error due to the intuitive matching of 
grammatical number.

## Profile Variables

This is a superset of the standard AIF profile variables. Each is listed below 
with its default values. None of these are required in a profile, though at the least
a HOSTNAME would make sense to customize.

### /etc/rc.conf related values
  * **HOSTNAME**="archlinux"
  * **LOCALE**="en_US.UTF-8"
  * **DAEMON_LOCALE**="no"
  * **HARDWARECLOCK**="UTC"
  * **TIMEZONE**="Canada/Pacific"
  * **KEYMAP**="us"
  * **CONSOLEFONT**="ter-120n"
  * **CONSOLEMAP**=
  * **USECOLOR**="yes"

### filesystem related
  * **GRUB_DEVICE**=/dev/sda
  * **PARTITIONS**='/dev/sda 100:ext2:+ 512:swap *:ext4'
  * **BLOCKDATA**='/dev/sda1 raw no_label 
  ext2;yes;/boot;target;no_opts;no_label;no_params
/dev/sda2 raw no_label swap;yes;no_mountpoint;target;no_opts;no_label;no_params
/dev/sda3 raw no_label ext4;yes;/;target;no_opts;no_label;no_params'

### rank mirrors
  * **RANKMIRRORS**=0 # set number of mirrors here; 0=don't run rankmirrors. 10 
  is good.

### coda
  * **CODA**='not yet implemented; block of commands to run at end of install.'

  * **RUNTIME_REPOSITORIES**=
  * **RUNTIME_PACKAGES**=

  * **TARGET_GROUPS**=

The following variables work with figtree but it's better to use the `packages` 
and `blacklist` commands.

  * **TARGET_PACKAGES_EXCLUDE**=
  * **TARGET_PACKAGES**=

## PATHS

Paths can be in one of three forms: relative, absolute and remote.

  * relative: `systems/make/model`

  * absolute: `/usr/lib/aif/user/figtree/systems/make/model`

  * remote:   `http://github.com/username/figtree/profiles/my-profile`

When looking for profiles in a given path, figtree looks first for a file named 
"profile" (this is the default, much like a webserver looks for a file named 
"index.html" in directory). If figtree doesn't find "profile" it looks for 
a match based on the last component of the path. Thus in the remote example 
above, figtree would first look for:

    http://github.com/username/figtree/profiles/my-profile/profile

and failing that would attempt to use:

    http://github.com/username/figtree/profiles/my-profile

### Relative

Given a relative profile, figtree will look for the profile in the same module 
as the source profile. Thus if you source a profile from
github using the following command line:

    # aif -p http://github.com/altercation/figtree/raw/master/procedures/automatic \\
          -c profiles/my-laptop

figtree will try to source the profile from the following location:

    http://github.com/username/figtree/profiles/my-laptop

The profile file itself has a default filename of `profile` though figtree can 
accept profiles with a different name as well. Thus:

    http://github.com/username/figtree/systems/lenovo/x220
          
will source either of the following files:

    http://github.com/username/figtree/systems/lenovo/*x220*
    http://github.com/username/figtree/systems/lenovo/x220/*profile*

The latter form (profile) is preferred as this allows the overlay directory to 
live in the same parent:

    http://github.com/username/figtree/systems/lenovo/x220/*overlay*

## Details

This procedure is similar to (and builds on) the standard AIF core automatic 
procedure. Indeed, it can be used as an almost seamless drop in replacement for 
it, though if your needs are met by the standard AIF core automatic procedure, 
it is recommended to use that as it has undergone considerably more testing.

## Current Issues & Status

1. AUR support is experimental. In VM based tests it works great sometimes but 
   I'm getting some I/O errors other times. I haven't solved this yet and it's 
   top of my bug list right now.

## Missing Features

Most of these were present in my old enconform script but I haven't 
reimplemented them in figtree. They are second level priority after issues 
above.

1. User creation / configuration during install
2. Sudoers configuration
3. Variable/Overlay file diff reporting (i.e. "what's different" between 
   current system and what figtree would do)

## Example Profile 0 (simple)

profiles/es-system

    depend_profile users/es
    HOSTNAME="es-archlinux"
    packages vim another-package-here

## Example Profile 1

profiles/es-laptop/profile

    #!/bin/bash

    # CONFIG-TREE
    # =============================================================================
    depend_profile users/es
    depend_profile environments/xmonad/es
    depend_profile applications/cli/thebasics
    depend_profile applications/cli/av
    depend_profile systems/lenovo/x220

    # SYSTEM CONFIG VALUES
    # =============================================================================
    # most of these are default values and can be left out (so we could specify
    # only the HOSTNAME, for instance
    HOSTNAME="es-laptop"
    LOCALE="en_US.UTF-8"
    DAEMON_LOCALE="no"
    HARDWARECLOCK="UTC"
    TIMEZONE="Canada/Pacific"
    KEYMAP="us"
    CONSOLEFONT="ter-120n"
    CONSOLEMAP=
    USECOLOR="yes"

    # OVERLAY FILES (in addition to those in the linked profiles)
    # =============================================================================
    overlay /etc/anoverlay/file

    # FILESYSTEM CONFIGURATION
    # =============================================================================
    # these could be left out and defaults would be used, but it's best to specify
    # them in the file as you desire
    GRUB_DEVICE=/dev/sda
    PARTITIONS='/dev/sda 100:ext2:+ 512:swap *:ext4'
    BLOCKDATA='/dev/sda1 raw no_label ext2;yes;/boot;target;no_opts;no_label;no_params
    /dev/sda2 raw no_label swap;yes;no_mountpoint;target;no_opts;no_label;no_params
    /dev/sda3 raw no_label ext4;yes;/;target;no_opts;no_label;no_params'

    # INSTALL OPTIONS
    # =============================================================================
    RANKMIRRORS=0 # set number of mirrors here; 0=don't run rankmirrors

    # =============================================================================
    # Don't modify items below unless you have cause to. Rather, use the following
    # commands (here or in depend_profile config files):
    #
    # packages  packagename [packagename...]
    # package_groups groupname [groupname...]
    # blacklist packagename [packagename...] (same as blacklisting a package)
    # -----------------------------------------------------------------------------
    # config    set /config/file/path VALUENAME "value to set"
    # config    unset /config/file/path VALUENAME (comments out the value)
    # daemons   add daemonname [@daemonname] [!daemonname]
    # daemons   remove daemonname [daemonname...]
    # modules   add modulename [modulename...]
    # modules   remove modulname [modulename...]
    # modules   add networkname [networkname...]
    # modules   remove networkname [networkname...]
    # overlay   /install/path/file [/another/file/here]
    #           (place the file in the overlay directory or use the
    #            figtree module partial-update-overlay procedure)
    # coda      'misc command to be run at end of installation goes-here'
    # -----------------------------------------------------------------------------
    # kernelparams parameter list here
    #
    # plural and singular forms of each command are equivalent in order to 
    # eliminate a common error in the config syntax:
    # -----------------------------------------------------------------------------
    # packages|package package_groups|package_group blacklist|blacklists 
    # config|configs daemons|daemon modules|module networks|network 
    # kernelparams|kernelparam coda|codas overlays|overlay
    # -----------------------------------------------------------------------------
    # the following are equivalent and may be used interchangeably 
    # add==set  unset==remove==delete

    # =============================================================================
    # RUNTIME_REPOSITORIES / RUNTIME_PACKAGES
    # =============================================================================
    RUNTIME_REPOSITORIES=
    RUNTIME_PACKAGES=

    # INSTALL PACKAGES
    # =============================================================================
    TARGET_GROUPS=
    TARGET_PACKAGES_EXCLUDE=
    TARGET_PACKAGES=

## Example Profile 2

systems/lenovo/x220/profile

    #!/bin/base

    # NETWORKING
    # =============================================================================
    packages netcfg rfkill wpa_supplicant wpa_actiond ifplugd wifi-select-git
    config unset /etc/rc.conf INTERFACES
    config unset /etc/rc.conf eth0
    config unset /etc/rc.conf eth1
    config set   /etc/rc.conf WIRED_INTERFACE eth0
    config set   /etc/rc.conf WIRELESS_INTERFACE wlan0
    networks add main home # just adds to NETWORKS in /etc/rc.conf
    daemons remove network # no longer required due to netcfg
    daemons add @net-auto-wired @net-auto-wireless
    overlay /etc/wpa_supplicant.conf /etc/network.d/ethernet-dhcp

    # POWER
    # =============================================================================
    packages acpi acpid acpitool pm-utils cpufrequtils thinkfan lm_sensors
    daemons add @acpi @sensors @thinkfan
    modules add thinkpad_acpi acpi_cpufreq cpufreq_ondemand cpufreq_powersave
    overlay /etc/acpi/handler.sh # acpi events and hotkeys
    overlay /etc/pm/power.d/cpu
    overlay /etc/pm/power.d/display
    overlay /etc/pm/power.d/network
    overlay /etc/pm/power.d/save-state
    overlay /etc/pm/power.d/sound
    overlay /etc/pm/sleep.d/11netcfg
    overlay /etc/pm/sleep.d/90alsa
    overlay /etc/thinkfan.conf

    # INPUT
    # =============================================================================
    packages xbindkeys
    overlay /lib/udev/keymaps/lenovo-thinkpad_x220_tablet
    overlay /etc/udev/rules.d/95-keymap.rules
    overlay /etc/X11/xinit/xinitrc
    overlay /etc/X11/xinit/Xmodmap
    overlay /etc/X11/xinit/xbindkeysrc
    overlay /usr/local/bin/rotate-screen
    packages xf86-input-wacom-git input-wacom-git

    # SOUND
    # =============================================================================
    packages alsa-utils alsa-oss alsa-equalizer
    daemons add @alsa
    overlays /var/lib/alsa/asound.state

    # DISPLAY
    # =============================================================================
    packages libdrm dri2proto xf86-video-intel
    packages xorg-server xorg-xinit xorg-utils xorg-server-utils xf86-input-synaptics
    packages mesa xorg-xlsfonts xdotool unclutter # mesa-demos
    overlays /etc/drirc # experimental
    overlays /etc/X11/xorg.conf.d/90-monitor.conf # to fix lcd monitor dpi size
    config set /etc/mkinitcpio.conf MODULES "i915"

    # TIME
    # =============================================================================
    packages ntp
    daemon remove hwclock
    daemon add @ntp

    # EXTRAS
    # =============================================================================
    # i915.i915_enable_rc6=1 to address power regression in linux 3.0.
    # TODO: monitor whether this continues to be required
    kernel_params 'i915.modeset=1 quiet hibernate=noresume logo.nologo cryptdevice=/dev/sda4:crypto i915.i915_enable_rc6=1 i915.powersave=1'

