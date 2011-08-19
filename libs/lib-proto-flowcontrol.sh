#!/bin/bash

# we have to add some flowcontrol functions and possibly override some of 
# core/libs/lib-flowcontrol.sh, specifically to easily load system config 
# files, source overlay files? and possible even load the correct procedure 
# given a url
# 
# really any of the load_ functions might need to be overridden and they might 
# actually need to be overridden in the procedure itself as we can only load 
# that single file from aif initially

load_
