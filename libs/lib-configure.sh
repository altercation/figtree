#!/bin/bash

# lib-config.sh provides system configuration functions to AIF workers.  
# Specifically it addresses three use cases:
#
# 1. the need to add, alter or remove a single "line item" configuration 
# variable. For example, changing a single variable in /etc/rc.conf
#
# 2. the need to add, alter, or remove an array value, for instance from 
# DAEMONS or MODULES
#
# 3. use of an "overlay" subdirectory to write out a set of predefined system 
# configuration files (for example, /etc/acpi/handler.sh)


