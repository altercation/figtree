1. rename to final release name
2. test on mercurial, svn
3. test on other git servers
4. add wget/ftp support?

5. integrate with existing AIF testing framework
6. improve libui use; normalize use of inform/notify/warnings; 

7. improve error handling; doesn't yet conform to the way AIF really does 
   things (workers, phases, etc. have some built in error handling that I haven't 
   fully explored yet)

8. Improve the intelligence of module paths. It should, ideally, act more like 
   a tree and less like a simple list

9. Confirm I'm not really overwriting TARGET_PACKAGES as I think I am.

10. what about multiple types of repositories...

11. cron support
12. sudoers support

current:

process_args (in automatic)
load_module  (in flow control)

are the two that need to be changed. questions:

1. load_module ... what else uses this? can we get it from the procedure or is it called before load_procedure?

process args just gets a lot of logic added to work through our profile heuristic. i should add a "load_profile" function so that process args is more single purpose.


#if net is install source, we should if/then for sync_url presence?

ADD: query-user function
(dieter's ui libs must have something like this already)


understand how SYNC_URL is used vs. "RUNTIME_REPOSITORIES"


why is:
    HARDWARECLOCK=${HARDWARECLOCK:-UTC}
        TIMEZONE=${TIMEZONE:-America/Los_Angeles}
in worker config NOT var_HARDWARECLOCK? shouldn't all internal variable to the 
procedure be var_ for consistency?

Confirm that DEFAULTFS isn't used anymore, despite the places it's hanging 
around
DEFAULTFS="/boot:32:ext2:+ swap:256:swap /:7500:ext3 /home:*:ext3"




# if archproto is in user
aif -p archproto/automatic -c http://github.com/altercation/archproto/profiles/es-laptop

# if archproto is not in user
aif -p http://github.com/altercation/archproto/procedures/automatic -c es-laptop
# if archproto is not in user and we just want to use the system profile, not a user profile
aif -p http://github.com/altercation/archproto/procedures/automatic -s lenovo/x220t

maybe better just to use -c and a subdir name, e.g system/lenovo/x220t
in that case, we can totally not worry about any special locations and we get the benefits 
of arbitrary subdirs and clarity in purpose (assuming the subdir is well named)

we could always make a future interactive function that just takes a subdir as starting point (systems) and allows the user to drill down till a directory containing a profile is found

this also allows for easy subvariants
lenovo/x220/laptop
lenovo/x220/tablet

in which case we need to be able to depend_profile on other profiles
i.e. depend_profile systems/lenovo/x220/laptop

so we take the aif module path and that is the provisional path for the archproto module (remote, local)

aif.sh sets $module and $procedure
$module can be http with $procedure taking the full path
if $module isn't http then it is a local path and we use the same logic as load_procedure to set the ARCHPROTO_MODULE_PATH
if $module is http and we have a relative path on -c then we download the whole repo and set ARCHPROTO_MODULE


if $module is local
        and config is relative
        and config is absolute
        and config is remote
else if $module is remote
        and config is relative
        and config is absolute
        and config is remote


see how much of this can be simply by overriding existing functions and proposing patches later

this allows us to JUST use aif the same as before!

if head of config path is http then it is remote
if head of config path is / then it is an absolute path
otherwise config path is assumed to be relative and we look for it first in local dir and then in aif user/archproto dir



# if archproto is not in user and we have archproto and config archives in separate repos/locations
aif -p http://github.com/altercation/archproto/procedures/automatic -c http://github/altercation/dotfiles/archproto/profiles/es-laptop

#todo: need to be able to depend_system
#maybe we can abstract that so that our "main" config can depend_profile on system/lenovo/x220...

# if we want to abstract all subdirs (other than procedures and libs) to be arbitrary profile containers:
aif -p http://github.com/altercation/archproto/procedures/automatic -c profiles/es-laptop
# then our partial procedure could be used post-intallation:
aif -p archproto/partial-archproto-install -c systems/lenovo/x220
aif -p archproto/partial-archproto-install -s lenovo/x220
# and conform (install missing items, note differences without overwriting)
aif -p archproto/partial-archproto-conform -c systems/lenovo/x220
aif -p archproto/partial-archproto-conform -s lenovo/x220
# and diff to identify what's missing, what's different
aif -p archproto/partial-archproto-diff -c systems/lenovo/x220
aif -p archproto/partial-archproto-diff -s lenovo/x220

our profile_load logic should:
1. check if basename is "profile", warn the user that it's unnecessary and then change the url and recall itself
OR NO WARNING... JUST STRIP AND RECALL function (or proceed with new value with no recall) TO IDENTIFY CORRECT PATH
2. check if the item downloaded is a file or directory. if a file then use it (so es-laptop could be a profile itself) or if a directory then look for "profile"
3. look for overlay subdir in same directory as profile file





search path priorities given a relative profile path:


# ------------------------------------------------------------------------
# from aif with local procedure:
# ------------------------------------------------------------------------

aif -p archproto/automatic -c systems/lenovo/x220

NOT...1. $PWD
procedure's module (e.g. /usr/lib/aif/user/archproto)


# ------------------------------------------------------------------------
# from aif with remote procedure:
# ------------------------------------------------------------------------

aif -p http://github.com/username/reponame/archproto/procedures/automatic -c systems/lenovo/x220

1. $PWD
2. remote repository, downloaded and normalized to a local absolute path, trimmed to a module root (ARCHPROTO_MODULE_ROOT?)
3. default user module for archproto (e.g. /usr/lib/aif/user/archproto)



note: if a profile changes from the procedures module path (local OR remote), that profile path becomes the new default location for all subsequent imports unless specified otherwise


maybe depend_profile should send two values to load_profile: the current value of search_path and the profile name
