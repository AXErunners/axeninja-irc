set axeircbot_version "1.1.0"

set axeircbot_script [file tail [ dict get [ info frame [ info frame ] ] file ]]

set axeircbot_command_en ""
set axeircbot_command_fr ""

putlog "$::axeircbot_script v$::axeircbot_version (by elberethzone) loading..."
set putlogloaded "$::axeircbot_script v$::axeircbot_version (by elberethzone) loaded!"

set axeircbot_commandlist_en ""
set axeircbot_commandlist_fr ""

proc axeircbot_command_cmp {a b} {
  return [string compare [lindex $a 0] [lindex $b 0]]
}

# Load sub-scripts
set subfiles [glob -dir "$::axeircbot_dir" axeircbot.*.tcl]
putlog "== Found [llength $subfiles] sub-scripts to load:"
foreach subfile $subfiles {
  source $subfile
}

# Sort commands
set axeircbot_command_en [lsort -command axeircbot_command_cmp $axeircbot_command_en]
set axeircbot_command_fr [lsort -command axeircbot_command_cmp $axeircbot_command_fr]

# Prepare the command list for !help display
set idxn 0
set totnen [llength $axeircbot_command_en]
set totn [expr $totnen-1]
foreach line $axeircbot_command_en {
  set command [lindex $line 0]
  set desc [lindex $line 1]
  if { $desc == "" } {
    set axeircbot_commandlist_en "$axeircbot_commandlist_en\( $command )"
  } else {
    set axeircbot_commandlist_en "$axeircbot_commandlist_en\( $command - $desc )"
  }
  if { $idxn < $totn } {
    set axeircbot_commandlist_en "$axeircbot_commandlist_en|"
  }
  incr idxn
}
set idxn 0
set totnfr [llength $axeircbot_command_fr]
set totn [expr $totnen-1]
foreach line $axeircbot_command_fr {
  set command [lindex $line 0]
  set desc [lindex $line 1]
  if { $desc == "" } {
    set axeircbot_commandlist_fr "$axeircbot_commandlist_fr\( $command )"
  } else {
    set axeircbot_commandlist_fr "$axeircbot_commandlist_fr\( $command - $desc )"
  }
  if { $idxn < $totn } {
    set axeircbot_commandlist_fr "$axeircbot_commandlist_fr|"
  }
  incr idxn
}

putlog "$putlogloaded (EN/FR $totnen/$totnfr commands registered)"
