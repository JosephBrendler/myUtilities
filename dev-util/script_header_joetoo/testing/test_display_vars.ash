#!/bin/sh
# test_display_vars.ash v0.1.0 

script_header_installed_dir=/home/joe/myUtilities/dev-util/script_header_joetoo

echo -n "sourcing test header"
source "${script_header_installed_dir}/script_header_joetoo"
right_status $?

_verbosity=${1:-1}

#-----[ variables ]------------------------------------------------------------------------------------
PN=$(basename "$0")

varlist="v1 v2 BREAK bool.VERBOSE verbosity yn.test _j_tw lv.longone"
v1=-55
v2=baretta
verbosity=3
VERBOSE=$TRUE
test=yes
_j_tw=$(termwidth)
longone="Amy shared a disturbing story of severed human heads being hung up on display at a popular tourist beach in Ecuador. Bobby shared his experience in Central America and if he felt safe while working down there. We discussed if self-driving cars are safer after a passenger jumped out of one that was approaching a train. We also played the crazy video of singer Craig Campbell using the self-driving feature to get him home. A show member wants to know if Bobby is ignoring their texts? Bobby shares the moment of clarity he had that made him realize the real meaning of life that for the first time put him at ease. Amy shared something that came up about Bobby during the baby shower where everyone wondered how he took care of himself before meeting his wife."

#-----[ Execution ]------------------------------------------------------------------------------------
separator "${PN}" "(Integration Test)"
message "Terminal Width: ${_j_tw}"

# Calculate longest for the API
_longest=$(get_longest "$varlist")
message "Longest variable name length: ${_longest}"

# Execute display_vars with the calculated longest and the varlist
verbosity="$_verbosity" display_vars "${_longest}" "${varlist}"

separator "${PN}" "(Done)"
