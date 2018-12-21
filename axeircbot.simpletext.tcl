#!/usr/bin/tclsh
# Simple text return command for axeircbot

set axeircbot_simpletext_subversion "1.7"
set axeircbot_simpletext_script [file tail [ dict get [ info frame [ info frame ] ] file ]]

putlog "++ $::axeircbot_simpletext_script v$axeircbot_simpletext_subversion loading..."

# -----------------------------------------------------------------------------
# Send text action
# -----------------------------------------------------------------------------
proc do_sendtext {action nick chan} {
  putlog "axeircbot v$::axeircbot_version ($::axeircbot_simpletext_script v$::axeircbot_simpletext_subversion) \[I\] [lindex [info level 0] 0] action $action from $nick in $chan"
  if {[string tolower $nick] == "alit"} {
    set header "PRIVMSG $nick :"
    puthelp "PRIVMSG $chan :$nick: 8===3 ~� ( O )"
    return
  }
  if {$action == "donate"} {
    set outtextfr "Donations aprecies sur Xbon36F261wXDL4p1CEZAX28t8U4ayR9uu"
    set outtexten "Donations and tips appreciated on Xbon36F261wXDL4p1CEZAX28t8U4ayR9uu"
  } elseif {$action == "infotest"} {
    set outtexten "COMMANDS: $::axeircbot_commandlist_en"
    set outtextfr "COMMANDES: $::axeircbot_commandlist_fr"
  } else {
    set outtexten "Commands: ( !mnstatsusd & !mnstatseur - MasterNodes Statistics )|( !mnworthusd & !mnwortheur - Daily earnings for masternodes )|( !worthusd & !wortheur - Trading prices )|( !marketcap & !marketcapeur - Market cap for AXE )|( !diff - Difficulty info )|( !donate )"
    set outtextfr "Commandes: ( !mnstatsusd & !mnstatseuro - Statistiques MasterNodes )|( !mnvaleur & !mnvaleureur - Gain Masternode )|( !valeur & !valeurusd - Valeur AXE )|( !marketcap & !marketcapusd - Capitalisation marche )|( !diff - Information difficulte )|( !donate )"
  }
  if {$chan == "#axe-fr"} {
    puthelp "PRIVMSG $chan :$nick: $outtextfr"
  } elseif {$chan == "PRIVATE"} {
    puthelp "PRIVMSG $nick :$outtexten"
  } else {
    puthelp "PRIVMSG $chan :$nick: $outtexten"
  }
}

# Bindings

# !donate
proc pub:donate {nick host handle chan {text ""}} {
  do_sendtext "donate" $nick $chan
}
proc msg:donate {nick uhost handle text} {
  do_sendtext "donate" $nick "PRIVATE"
}
# !info
proc pub:axeinfo {nick host handle chan {text ""}} {
  do_sendtext "infotest" $nick $chan
}
proc msg:axeinfo {nick uhost handle text} {
  do_sendtext "infotest" $nick "PRIVATE"
}

bind msg - !donate msg:donate
bind pub - !donate pub:donate

bind msg - !list msg:axeinfo
bind pub - !list pub:axeinfo
bind msg - !commands msg:axeinfo
bind pub - !commands pub:axeinfo
bind msg - !help msg:axeinfo
bind pub - !help pub:axeinfo

lappend axeircbot_command_fr { {!donate} {} }
lappend axeircbot_command_en { {!donate} {} }

putlog "++ $::axeircbot_simpletext_script v$axeircbot_simpletext_subversion loaded!"
