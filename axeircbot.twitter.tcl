#!/usr/bin/tclsh
# Twitter feed display for axeircbot
package require mysqltcl

set axeircbot_twitter_subversion "1.10"
set axeircbot_twitter_script [file tail [ dict get [ info frame [ info frame ] ] file ]]

set axeircbot_twitter_timer ""
set axeircbot_twitter_lasttweetid 0

putlog "++ $::axeircbot_twitter_script v$axeircbot_twitter_subversion loading..."

proc do_fetch_lasttweetid {} {
  if {$::axeircbot_twitter_lasttweetid == 0} {
    if { [catch {set db [::mysql::connect -user $::axeircbot_mysqluser -password $::axeircbot_mysqlpass -db $::axeircbot_mysqldb]} errmsg] } {
      putlog "axeircbot v$::axeircbot_version ($::axeircbot_twitter_script v$::axeircbot_twitter_subversion) \[E\] [lindex [info level 0] 0] $errmsg"
    } else {
      if { [catch {set data [::mysql::sel $db "SELECT StatValue FROM cmd_stats_values WHERE StatKey = 'tweetlastdrkc'" -list]} errmsg] } {
        putlog "axeircbot v$::axeircbot_version ($::axeircbot_twitter_script v$::axeircbot_twitter_subversion) \[E\] [lindex [info level 0] 0] $errmsg"
        ::mysql::close $db
      } else {
        ::mysql::close $db
        set ::axeircbot_twitter_lasttweetid [lindex $data 0]
        putlog "axeircbot v$::axeircbot_version ($::axeircbot_twitter_script v$::axeircbot_twitter_subversion) \[I\] [lindex [info level 0] 0] success: $::axeircbot_twitter_lasttweetid"
      }
    }
  }
  return [expr $::axeircbot_twitter_lasttweetid > 0]
}

proc do_save_lasttweetid {} {
  if {$::axeircbot_twitter_lasttweetid != 0} {
    if { [catch {set db [::mysql::connect -user $::axeircbot_twitter_mysqluser -password $::axeircbot_twitter_mysqlpass -db $::axeircbot_mysqldb]} errmsg] } {
      putlog "axeircbot v$::axeircbot_version ($::axeircbot_twitter_script v$::axeircbot_twitter_subversion) \[E\] [lindex [info level 0] 0] $errmsg"
    } else {
      if { [catch {set data [::mysql::exec $db "UPDATE cmd_stats_values SET StatValue = $::axeircbot_twitter_lasttweetid WHERE StatKey = 'tweetlastdrkc'"]} errmsg] } {
        putlog "axeircbot v$::axeircbot_version ($::axeircbot_twitter_script v$::axeircbot_twitter_subversion) \[E\] [lindex [info level 0] 0] $errmsg"
        ::mysql::close $db
      } else {
        putlog "axeircbot v$::axeircbot_version ($::axeircbot_twitter_script v$::axeircbot_twitter_subversion) \[I\] [lindex [info level 0] 0] success: $::axeircbot_twitter_lasttweetid"
        ::mysql::close $db
      }
    }
  }
}

proc do_showtwitter {} {
  global axeircbot_twitter_timer axeircbot_twitter_screenname
  if { [catch {set test [exec $::axeircbot_twitter_updatescript]} errmsg] } {
    putlog "axeircbot v$::axeircbot_version ($::axeircbot_twitter_script v$::axeircbot_twitter_subversion) \[E\] [lindex [info level 0] 0] $errmsg"
  } else {
    if {[do_fetch_lasttweetid]} {
      if { [catch {set db [::mysql::connect -user $::axeircbot_mysqluser -password $::axeircbot_mysqlpass -db $::axeircbot_mysqldb]} errmsg] } {
        putlog "axeircbot v$::axeircbot_version ($::axeircbot_twitter_script v$::axeircbot_twitter_subversion) \[E\] [lindex [info level 0] 0] $errmsg"
      } else {
        if { [catch {set data [::mysql::sel $db "SELECT * FROM cmd_twitter WHERE account = '$axeircbot_twitter_screenname' AND id > $::axeircbot_twitter_lasttweetid ORDER BY id" -list]} errmsg] } {
          putlog "axeircbot v$::axeircbot_version ($::axeircbot_twitter_script v$::axeircbot_twitter_subversion) \[E\] [lindex [info level 0] 0] $errmsg"
          ::mysql::close $db
        } else {
          ::mysql::close $db
          if {[llength $data] > 0} {
            foreach line $data {
              putlog "axeircbot v$::axeircbot_version ($::axeircbot_twitter_script v$::axeircbot_twitter_subversion) \[I\] [lindex [info level 0] 0] New tweet: [lindex $line 0] ([lindex $line 2]): [lindex $line 3]"
              regsub -all {\n} [lindex $line 3] " " tweettext
              puthelp "PRIVMSG #axe-fr :TWITTER FEED [lindex $line 0] ([lindex $line 2]): $tweettext"
              puthelp "PRIVMSG #axerunners :TWITTER FEED [lindex $line 0] ([lindex $line 2]): $tweettext"
              if {[lindex $line 1] > $::axeircbot_twitter_lasttweetid} {
                set ::axeircbot_twitter_lasttweetid [lindex $line 1]
              }
            }
            do_save_lasttweetid
          } else {
            putlog "axeircbot v$::axeircbot_version ($::axeircbot_twitter_script v$::axeircbot_twitter_subversion) \[I\] [lindex [info level 0] 0] - No new tweets"
          }
        }
      }
    } else {
      putlog "axeircbot v$::axeircbot_version ($::axeircbot_twitter_script v$::axeircbot_twitter_subversion) \[E\] [lindex [info level 0] 0] Failed!"
    }
  }
  timer 5 do_showtwitter
}

proc do_killtwitter {} {
  foreach ctimer [timers] {
    if { [lindex $ctimer 1] == "do_showtwitter" } {
      killtimer [lindex $ctimer 2]
    }
  }
}

# Bindings
proc dcc:killtwitter {handle idx text} {
  do_killtwitter
}
proc dcc:starttwitter {handle idx text} {
  do_showtwitter
}

bind dcc m|m killtwitter dcc:killtwitter
bind dcc m|m starttwitter dcc:starttwitter

putlog "++ $::axeircbot_twitter_script v$axeircbot_twitter_subversion loaded!"
do_showtwitter
