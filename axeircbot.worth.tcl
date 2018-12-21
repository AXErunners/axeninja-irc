#!/usr/bin/tclsh
# Worth command for axeircbot
package require http
package require tls
package require json

::http::register https 443 [list ::tls::socket -tls1 1]

set axeircbot_worth_subversion "2.17"
set axeircbot_worth_script [file tail [ dict get [ info frame [ info frame ] ] file ]]

set axeircbot_translation [dict create \
                                    "usage_calc" [dict create \
        "en" "Usage: !calc\[fiat\] <hashrate_in_khs> - \[fiat\] can be eur or usd (default: usd) - Ex: !calc 10000" \
        "fr" "Utilisation: !calc\[fiat\] <hachage_en_khs> - \[fiat\] peux être eur ou usd (par défaut: usd) - Ex: !calc 10000\]"] \
                                    "usage_diff" [dict create \
        "en" "Usage: !diff \[difficulty_value\] - If no difficulty is given as parameter, will use current one." \
        "fr" "Utilisation: !diff \[valeur_difficulté\] - Si la difficulté n'est pas spécifié, utilisera l'actuelle."] \
                                    "usage_mnworth" [dict create \
        "en" "Usage: !mnworth\[fiat\] <number_of_masternodes> - \[fiat\] can be eur or usd (default: usd) - Ex: !mnworth 2 or !mnw" \
        "fr" "Utilisation: !mnvaleur\[fiat\] <nombre_de_masternodes> - \[fiat\] peux être eur ou usd (par défaut: usd) - Ex: !mnvaleur 2 ou !mnv"] \
                                    "usage_worth" [dict create \
        "en" "Usage: !worth\[fiat\] <amount_AXE|AXE_Address> - \[fiat\] can be eur or usd (default: usd) - Ex: !worth 1234.5 or !worth Xr57hNKbEzNHFkTsUmfhPxKRfnnt9nVe7z or !w 76" \
        "fr" "Utilisation: !valeur\[fiat\] <montant_AXE|Addresse_AXE> - \[fiat\] peux être eur ou usd (par défaut: usd) - Ex: !valeur 1234.5 ou !valeur Xr57hNKbEzNHFkTsUmfhPxKRfnnt9nVe7z ou !v 76"] \
                                    "action_unavailable" [dict create \
        "en" "Command is temporarily unavailable." \
        "fr" "Commande temporairement indisponible."] \
                                    "action_unknown" [dict create \
        "en" "Command %s is unknown." \
        "fr" "Commande %s inconnue."] \
                                    "result_calc" [dict create \
        "en" "With last 24h supply of %s AXE (source:%s|%s) and a network hashrate of %s (source:%s|%s) your %s would have generated %.9f AXE @ %s AXE/BTC (source:%s|%s) = %.9f BTC/Day / %.2f %s/Day (source:%s|%s)" \
        "fr" "Avec %s générés ces derniéres 24h (source:%s|%s) et un hachage réseau de %s (source:%s|%s) vos %s aurais généré %.9f AXE @ %s AXE/BTC (source:%s|%s) = %.9f BTC/Day / %.2f %s/Day (source:%s|%s)"] \
                                    "result_diff" [dict create \
        "en" "%s difficulty: %s%s Coin generation: %.2f AXE miner (%s%%) + %.2f AXE masternode (%s%%) + %.2f AXE budgets (%s%%) = %.2f AXE total" \
        "fr" "Difficulté %s: %s%s Génération de piéces: %.2f AXE mineur (%s%%) + %.2f AXE masternode (%s%%) + %.2f AXE budgets (%s%%) = %.2f AXE au total"] \
                                    "result_diff_asked" [dict create \
        "en" "Asked" \
        "fr" "demandée"] \
                                    "result_diff_current" [dict create \
        "en" "Current" \
        "fr" "actuelle"] \
                                    "result_diff_source" [dict create \
        "en" " (source:%s|%s)" \
        "fr" " (source:%s|%s)"] \
                                    "result_marketcap" [dict create \
        "en" "AXE position = %d with %s BTC market cap (%s %s with supply of %s AXE) and a 24h volume of %s BTC (%s %s) %s%% (source:%s|%s)" \
        "fr" "Position AXE = %d avec une capitalisation marche de %s BTC (%s %s avec un total de %s AXE) et un volume journalier de %s BTC (%s %s) %s%% (source:%s|%s)"] \
                                    "result_mnstats" [dict create \
        "en" "%d active masternodes (source:%s|%s) ATH = %d (%s UTC) @ %s AXE/BTC (source:%s|%s) = %.2f BTC / %.2f %s in stake (source:%s|%s)" \
        "fr" "%d active masternodes (source:%s|%s) ATH = %d (%s UTC) @ %s AXE/BTC (source:%s|%s) = %.2f BTC / %.2f %s en épargne (source:%s|%s)"] \
                                    "result_mnworth" [dict create \
        "en" "%s masternodes = %.3f AXE/Day (source:%s|%s) using %s%% blocks paid at %s%% last 24h (source:%s|%s) @ %s AXE/BTC (source:%s|%s) = %.9f BTC/Day / %.2f %s/Day (source:%s|%s)" \
        "fr" "%s masternodes = %.3f AXE/Jour (source:%s|%s) avec %s%% des blocs payés à %s%% ces dernières 24h (source:%s|%s) @ %s AXE/BTC (source:%s|%s) = %.9f BTC/Jour / %.2f %s/Jour (source:%s|%s)"] \
                                    "result_worth" [dict create \
        "en" "%s AXE @ %s AXE/BTC (source:%s|%s) = %.6f BTC / %.2f %s (source:%s|%s)" \
        "fr" "%s AXE @ %s AXE/BTC (source:%s|%s) = %.6f BTC / %.2f %s (source:%s|%s)"] \
 ]

set axeircbot_tablevar_refreshinterval 30

putlog "++ $::axeircbot_worth_script v$axeircbot_worth_subversion loading..."

set axeircbot_tablevar [dict create]
set axeircbot_tablevarlast 0

proc axeircbot_getdeltatime {from to} {

  set res ""
  set delta [expr $to-$from]
  if {$delta < 0} {
    set delta 0
  }
  set deltasec [expr $delta%60]
  set deltamin [expr ($delta/60)%60]
  set deltahour [expr ($delta/3600)%24]
  set deltaday [expr int(floor($delta/86400))]
#  putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[I\] [lindex [info level 0] 0] $delta $deltasec $deltamin $deltahour $deltaday"
  if {$deltaday > 0} {
    set res "$res[format "%d" $deltaday]d"
  }
  if {$deltahour > 0} {
    set res "$res[format "%d" $deltahour]h"
  }
  if {$deltamin > 0} {
    set res "$res[format "%d" $deltamin]m"
  }
  set res "$res[format "%d" $deltasec]s"
  return $res
}

proc axeircbot_hrhashpers {hashper} {

  set hashper [expr double($hashper)]
  set res ""
  if {$hashper >= 1000000000000} {
    set calchps [expr $hashper/1000000000000]
    set res  [format "%.2f Th/s" $calchps]
  } elseif {$hashper >= 1000000000} {
    set calchps [expr $hashper/1000000000]
    set res [format "%.2f Gh/s" $calchps]
  } elseif {$hashper >= 1000000} {
    set calchps [expr $hashper/1000000]
    set res [format "%.2f Mh/s" $calchps]
  } elseif {$hashper >= 1000} {
    set calchps [expr $hashper/1000]
    set res [format "%.2f kh/s" $calchps]
  } else {
    set res "$hashper h/s"
  }
  return $res
}

proc axeircbot_unavailable {header lang} {
  puthelp "$header [dict get [dict get $::axeircbot_translation "action_unavailable"] $lang]"
}

proc axeircbot_refresh_tablevar {} {
  set now [clock seconds]
  if {$now > [expr $::axeircbot_tablevarlast+$::axeircbot_tablevar_refreshinterval]} {
    putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[I\] [lindex [info level 0] 0] refreshing tablevar (last from [clock format $::axeircbot_tablevarlast -format {%Y-%m-%d %H:%M:%S} -gmt true])"
    if { [catch {set httptoken [http::geturl "https://explorer.axeninja.pl/chain/AXE/q/getblockcount" -timeout 2000]} errmsg] } {
      http::cleanup $httptoken
      putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[E\] [lindex [info level 0] 0] $errmsg"
    } elseif { [http::status $httptoken] != "ok" } {
      putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[E\] [lindex [info level 0] 0] HTTP Status: [http::status $httptoken]"
      http::cleanup $httptoken
    } else {
      set blockcountraw [http::data $httptoken]
      http::cleanup $httptoken
      dict set ::axeircbot_tablevar "blockcount" [list $blockcountraw "[clock seconds]" "axeninja"]
#      putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[I\] [lindex [info level 0] 0] OK (blockcount: $blockcountraw) = $::axeircbot_tablevar]"
    }
    if { [catch {set httptoken [http::geturl "https://explorer.axeninja.pl/chain/AXE/q/getdifficulty" -timeout 2000]} errmsg] } {
      http::cleanup $httptoken
      putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[E\] [lindex [info level 0] 0] $errmsg"
    } elseif { [http::status $httptoken] != "ok" } {
      putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[E\] [lindex [info level 0] 0] HTTP Status: [http::status $httptoken]"
      http::cleanup $httptoken
    } else {
      set difficultyraw [http::data $httptoken]
      http::cleanup $httptoken
      dict set ::axeircbot_tablevar "difficulty" [list $difficultyraw "[clock seconds]" "axeninja"]
#      putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[I\] [lindex [info level 0] 0] OK (difficulty: $difficultyraw) = $::axeircbot_tablevar]"
    }
    if { [catch {set httptoken [http::geturl "https://www.axeninja.pl/api/tablevars" -timeout 2000]} errmsg] } {
      http::cleanup $httptoken
      putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[E\] [lindex [info level 0] 0] $errmsg"
    } elseif { [http::status $httptoken] != "ok" } {
      putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[E\] [lindex [info level 0] 0] HTTP Status: [http::status $httptoken]"
      http::cleanup $httptoken
    } else {
      set jsonraw [http::data $httptoken]
      http::cleanup $httptoken
      if { [catch {set json [::json::json2dict $jsonraw]} errmsg] } {
        putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[E\] [lindex [info level 0] 0] $errmsg"
      } elseif { [dict get $json status] != "OK" } {
        putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[E\] [lindex [info level 0] 0] HTTP Status: [dict get $json status]"
      } else {
        set json [dict get $json data tablevars]
        dict for {key val} $json {
          dict set ::axeircbot_tablevar $key [list [dict get $val StatValue] [dict get $val LastUpdate] [dict get $val Source]];
#          putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[I\] [lindex [info level 0] 0] OK ($key: [dict get $val StatValue]) = $::axeircbot_tablevar]"
        }
        set ::axeircbot_tablevarlast [clock seconds]
      }
    }
  }
  return [expr $::axeircbot_tablevarlast != 0]
}

proc axeircbot_tablevar_fetch { key } {
  if [dict exists $::axeircbot_tablevar $key] {
    return [dict get $::axeircbot_tablevar $key]
  } else {
    return [list false false false]
  }
}

proc do_worth {action fiat nick chan param} {
  putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[I\] [lindex [info level 0] 0] action $action $fiat from $nick in $chan"
  if {[string tolower $nick] == "alit"} {
    set header "PRIVMSG $nick :"
    puthelp "PRIVMSG $chan :$nick: 8===3 ~� ( O )"
    return
  }
  if {$chan == "PRIVATE"} {
    set header "PRIVMSG $nick :"
  } else {
    set header "PRIVMSG $chan :$nick:"
  }
  if {$chan == "#axe-fr"} {
    set lang "fr"
  } else {
    set lang "en"
  }
  if {[axeircbot_refresh_tablevar]} {
    set btcdrk [axeircbot_tablevar_fetch "btcdrk"]
    if { [lindex $btcdrk 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set eurobtc [axeircbot_tablevar_fetch "eurobtc"]
    if { [lindex $eurobtc 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set usdbtc [axeircbot_tablevar_fetch "usdbtc"]
    if { [lindex $usdbtc 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set mnactivecount [axeircbot_tablevar_fetch "mnactive"]
    if { [lindex $mnactivecount 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set mnactiveathcount [axeircbot_tablevar_fetch "mnactiveath"]
    if { [lindex $mnactiveathcount 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set last24hsupply [axeircbot_tablevar_fetch "last24hsupply"]
    if { [lindex $last24hsupply 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set paymentdrk [axeircbot_tablevar_fetch "paymentdrk"]
    if { [lindex $paymentdrk 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set mnpaymentratio [axeircbot_tablevar_fetch "mnpaymentratio"]
    if { [lindex $mnpaymentratio 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set minerpaymentratiodisp [expr round((1.0-double([lindex $mnpaymentratio 0]))*0.9*100)]
    set mnpaymentratiodisp [expr round(double([lindex $mnpaymentratio 0])*0.9*100)]
    set mnpayments [axeircbot_tablevar_fetch "mnpayments"]
    if { [lindex $mnpayments 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set mcappos [axeircbot_tablevar_fetch "marketcappos"]
    if { [lindex $mcappos 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set mcapbtc [axeircbot_tablevar_fetch "marketcapbtc"]
    if { [lindex $mcapbtc 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set mcapusd [axeircbot_tablevar_fetch "marketcapusd"]
    if { [lindex $mcapusd 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set mcapeur [axeircbot_tablevar_fetch "marketcapeur"]
    if { [lindex $mcapeur 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set mcapsupply [axeircbot_tablevar_fetch "marketcapsupply"]
    if { [lindex $mcapsupply 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    puts 2
    set mcapvolbtc [axeircbot_tablevar_fetch "volumebtc"]
    if { [lindex $mcapvolbtc 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set mcapvolusd [axeircbot_tablevar_fetch "volumeusd"]
    if { [lindex $mcapvolusd 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set mcapvoleur [axeircbot_tablevar_fetch "volumeeur"]
    if { [lindex $mcapvoleur 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set mcapchange [axeircbot_tablevar_fetch "marketcapchange"]
    if { [lindex $mcapchange 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    puts 3
    set difficulty [axeircbot_tablevar_fetch "difficulty"]
    if { [lindex $difficulty 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set blockcount [axeircbot_tablevar_fetch "blockcount"]
    if { [lindex $blockcount 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set networkhashpers [axeircbot_tablevar_fetch "networkhashpers"]
    if { [lindex $networkhashpers 0] == false } {
      axeircbot_unavailable $header $lang
      return
    }
    set drkpermn [expr ([lindex $paymentdrk 0]/[lindex $mnactivecount 0])]
    if {$action == "calc"} {
      if {$param == ""} {
        puthelp "$header [dict get [dict get $::axeircbot_translation "usage_calc"] $lang]"
        return
      }
      if { [catch {set userhashpers [expr int($param)*1000]} errmsg] } {
        puthelp "$header [dict get [dict get $::axeircbot_translation "usage_calc"] $lang]"
        return
      }
      if { $userhashpers <= 0 } {
        puthelp "$header [dict get [dict get $::axeircbot_translation "usage_calc"] $lang]"
        return
      }
      set gainaxe [expr ($userhashpers/double([lindex $networkhashpers 0]))*(double([lindex $last24hsupply 0])*(1-double([lindex $mnpaymentratio 0]))*0.9)]
      set amountbtc [expr $gainaxe*[lindex $btcdrk 0]]
      if {$fiat == "EUR"} {
        set amountfiat [expr $amountbtc*[lindex $eurobtc 0]]
        set fiatsource [lindex $eurobtc 2]
        set fiatdate [axeircbot_getdeltatime [lindex $eurobtc 1] [clock seconds]]
      } else {
        set amountfiat [expr $amountbtc*[lindex $usdbtc 0]]
        set fiatsource [lindex $usdbtc 2]
        set fiatdate [axeircbot_getdeltatime [lindex $usdbtc 1] [clock seconds]]
      }
      set outmsg [format [dict get [dict get $::axeircbot_translation "result_calc"] $lang] [lindex $last24hsupply 0] [lindex $last24hsupply 2] [axeircbot_getdeltatime [lindex $last24hsupply 1] [clock seconds]] [axeircbot_hrhashpers [lindex $networkhashpers 0]] [lindex $networkhashpers 2] [axeircbot_getdeltatime [lindex $networkhashpers 1] [clock seconds]] [axeircbot_hrhashpers $userhashpers] $gainaxe [lindex $btcdrk 0] [lindex $btcdrk 2] [axeircbot_getdeltatime [lindex $btcdrk 1] [clock seconds]] $amountbtc $amountfiat $fiat $fiatsource $fiatdate]
    } elseif {$action == "diff"} {
      if {$param != ""} {
        if { [catch {set diffval [expr double($param)]} errmsg] } {
          puthelp "$header [dict get [dict get $::axeircbot_translation "usage_diff"] $lang]"
          return
        }
        set difftext [dict get [dict get $::axeircbot_translation "result_diff_asked"] $lang]
        set diffsource ""
      } else {
        set diffval [expr double([lindex $difficulty 0])]
        set difftext [dict get [dict get $::axeircbot_translation "result_diff_current"] $lang]
        set diffsource [format [dict get [dict get $::axeircbot_translation "result_diff_source"] $lang] [lindex $difficulty 2] [axeircbot_getdeltatime [lindex $difficulty 1] [clock seconds]]]
      }
      set cursupply [expr round((2222222.0 / (pow(($diffval+2600.0)/9.0,2.0))))]
      if {$cursupply < 5} {
        set cursupply 5
      } elseif {$cursupply > 25} {
        set cursupply 25
      }
      for {set i 210240} {$i < $blockcount} {set i [expr $i+210240]} {
        set cursupply [expr $cursupply-($cursupply/14.0)]
      }
      set cursupplymn [expr $cursupply*double([lindex $mnpaymentratio 0])*0.9]
      set cursupplyminers [expr $cursupply*(1.0-double([lindex $mnpaymentratio 0]))*0.9]
      set cursupplybudget [expr $cursupply-$cursupplymn-$cursupplyminers]
      set outmsg [format [dict get [dict get $::axeircbot_translation "result_diff"] $lang] $difftext $diffval $diffsource $cursupplyminers $minerpaymentratiodisp $cursupplymn $mnpaymentratiodisp $cursupplybudget "10" $cursupply]
    } elseif {$action == "marketcap"} {
      if {$fiat == "EUR"} {
        set mcapfiat $mcapeur
        set mcapvol $mcapvoleur
      } else {
        set mcapfiat $mcapusd
        set mcapvol $mcapvolusd
      }
      set outmsg [format [dict get [dict get $::axeircbot_translation "result_marketcap"] $lang] [expr int([lindex $mcappos 0])] [lindex $mcapbtc 0] [lindex $mcapfiat 0] $fiat [lindex $mcapsupply 0] [lindex $mcapvolbtc 0] [lindex $mcapvol 0] $fiat [lindex $mcapchange 0] [lindex $mcapbtc 2] [axeircbot_getdeltatime [lindex $mcapbtc 1] [clock seconds]]]
    } elseif {$action == "mnstats"} {
      set lockedbtc [expr [lindex $mnactivecount 0]*1000*[lindex $btcdrk 0]]
      if {$fiat == "EUR"} {
        set lockedfiat [expr $lockedbtc*[lindex $eurobtc 0]]
        set fiatsource [lindex $eurobtc 2]
        set fiatdate [axeircbot_getdeltatime [lindex $eurobtc 1] [clock seconds]]
      } else {
        set lockedfiat [expr $lockedbtc*[lindex $usdbtc 0]]
        set fiatsource [lindex $usdbtc 2]
        set fiatdate [axeircbot_getdeltatime [lindex $usdbtc 1] [clock seconds]]
      }
      set outmsg [format [dict get [dict get $::axeircbot_translation "result_mnstats"] $lang] [lindex $mnactivecount 0] [lindex $mnactivecount 2] [axeircbot_getdeltatime [lindex $mnactivecount 1] [clock seconds]] [lindex $mnactiveathcount 0] [clock format [lindex $mnactiveathcount 1] -format "%d/%m/%Y %H:%M" -gmt 1] [lindex $btcdrk 0] [lindex $btcdrk 2] [axeircbot_getdeltatime [lindex $btcdrk 1] [clock seconds]] $lockedbtc $lockedfiat $fiat $fiatsource $fiatdate]
    } elseif {$action == "mnworth"} {
      if {$param == ""} {
        set $param "1"
      }
      if { [catch {set numbermn [expr double($param)]} errmsg] } {
        set numbermn 1.0
      }
      if { $numbermn <= 0 } {
        puthelp "$header [dict get [dict get $::axeircbot_translation "usage_mnworth"] $lang]"
        return
      }
      set amountdrk [expr $numbermn*$drkpermn*double([lindex $mnpayments 0])/100]
      set amountbtc [expr $amountdrk*[lindex $btcdrk 0]]
      if {$fiat == "EUR"} {
        set amountfiat [expr $amountbtc*[lindex $eurobtc 0]]
        set fiatsource [lindex $eurobtc 2]
        set fiatdate [axeircbot_getdeltatime [lindex $eurobtc 1] [clock seconds]]
      } else {
        set amountfiat [expr $amountbtc*[lindex $usdbtc 0]]
        set fiatsource [lindex $usdbtc 2]
        set fiatdate [axeircbot_getdeltatime [lindex $usdbtc 1] [clock seconds]]
      }
      set outmsg [format [dict get [dict get $::axeircbot_translation "result_mnworth"] $lang] $numbermn $amountdrk [lindex $last24hsupply 2] [axeircbot_getdeltatime [lindex $last24hsupply 1] [clock seconds]] [lindex $mnpayments 0] $mnpaymentratiodisp [lindex $mnpayments 2] [axeircbot_getdeltatime [lindex $mnpayments 1] [clock seconds]] [lindex $btcdrk 0] [lindex $btcdrk 2] [axeircbot_getdeltatime [lindex $btcdrk 1] [clock seconds]] $amountbtc $amountfiat $fiat $fiatsource $fiatdate]
    } elseif {$action == "worth"} {
      if {$param == ""} {
        puthelp "$header [dict get [dict get $::axeircbot_translation "usage_worth"] $lang]"
        return
      }
      if { [catch {set amountdrk [expr double($param)]} errmsg] } {
        set lenparam [string length $param]
        if {$lenparam != 34} {
          puthelp "$header [dict get [dict get $::axeircbot_translation "usage_worth"] $lang]"
          return
        }
        set firstchar [string index $param 0]
        if {$firstchar != "X"} {
          puthelp "$header [dict get [dict get $::axeircbot_translation "usage_worth"] $lang]"
          return
        }
        if { [catch {set wsresult [http::data [http::geturl "https://explorer.axeninja.pl/chain/AXE/q/addressbalance/$param" -timeout 2000]]} errmsg] } {
          putlog "axeircbot v$::axeircbot_version ($::axeircbot_worth_script v$::axeircbot_worth_subversion) \[E\] [lindex [info level 0] 0] webservice error: $errmsg"
          puthelp "$header [dict get [dict get $::axeircbot_translation "usage_worth"] $lang]"
          return
        }
        if { [catch {set amountdrk [expr double($wsresult)]} errmsg] } {
          puthelp "$header [dict get [dict get $::axeircbot_translation "usage_worth"] $lang]"
          return
        }
      }
      if { $amountdrk <= 0 } {
        puthelp "$header [dict get [dict get $::axeircbot_translation "usage_worth"] $lang]"
        return
      }
      set amountbtc [expr $amountdrk*[lindex $btcdrk 0]]
      if {$fiat == "EUR"} {
        set amountfiat [expr $amountbtc*[lindex $eurobtc 0]]
        set fiatsource [lindex $eurobtc 2]
        set fiatdate [axeircbot_getdeltatime [lindex $eurobtc 1] [clock seconds]]
      } else {
        set amountfiat [expr $amountbtc*[lindex $usdbtc 0]]
        set fiatsource [lindex $usdbtc 2]
        set fiatdate [axeircbot_getdeltatime [lindex $usdbtc 1] [clock seconds]]
      }
      set outmsg [format [dict get [dict get $::axeircbot_translation "result_worth"] $lang] $amountdrk [lindex $btcdrk 0] [lindex $btcdrk 2] [axeircbot_getdeltatime [lindex $btcdrk 1] [clock seconds]] $amountbtc $amountfiat $fiat $fiatsource $fiatdate]
    } else {
     set outmsg [format [dict get [dict get $::axeircbot_translation "action_unknown"] $lang] $action]
    }
    puthelp "$header $outmsg"
  } else {
    axeircbot_unavailable $header $lang
  }
}

# Bindings

# !calc
proc pub:calcusd {nick host handle chan {text ""}} {
  do_worth "calc" "USD" $nick $chan $text
}
proc msg:calcusd {nick uhost handle text} {
  do_worth "calc" "USD" $nick "PRIVATE" $text
}
proc pub:calceur {nick host handle chan {text ""}} {
  do_worth "calc" "EUR" $nick $chan $text
}
proc msg:calceur {nick uhost handle text} {
  do_worth "calc" "EUR" $nick "PRIVATE" $text
}
# !diff
proc pub:diff {nick host handle chan {text ""}} {
  do_worth "diff" "" $nick $chan $text
}
proc msg:diff {nick uhost handle text} {
  do_worth "diff" "" $nick "PRIVATE" $text
}
# !marketcap*
proc pub:marketcapusd {nick host handle chan {text ""}} {
  do_worth "marketcap" "USD" $nick $chan ""
}
proc msg:marketcapusd {nick uhost handle text} {
  do_worth "marketcap" "USD" $nick "PRIVATE" ""
}
proc pub:marketcapeur {nick host handle chan {text ""}} {
  do_worth "marketcap" "EUR" $nick $chan ""
}
proc msg:marketcapeur {nick uhost handle text} {
  do_worth "marketcap" "EUR" $nick "PRIVATE" ""
}
# !mnstats*
proc pub:mnstatsusd {nick host handle chan {text ""}} {
  do_worth "mnstats" "USD" $nick $chan ""
}
proc msg:mnstatsusd {nick uhost handle text} {
  do_worth "mnstats" "USD" $nick "PRIVATE" ""
}
proc pub:mnstatseur {nick host handle chan {text ""}} {
  do_worth "mnstats" "EUR" $nick $chan ""
}
proc msg:mnstatseur {nick uhost handle text} {
  do_worth "mnstats" "EUR" $nick "PRIVATE" ""
}
# !mnworth*
proc pub:mnworthusd {nick host handle chan {text ""}} {
  do_worth "mnworth" "USD" $nick $chan $text
}
proc msg:mnworthusd {nick uhost handle text} {
  do_worth "mnworth" "USD" $nick "PRIVATE" $text
}
proc pub:mnwortheur {nick host handle chan {text ""}} {
  do_worth "mnworth" "EUR" $nick $chan $text
}
proc msg:mnwortheur {nick uhost handle text} {
  do_worth "mnworth" "EUR" $nick "PRIVATE" $text
}
# !worth*
proc pub:worthusd {nick host handle chan {text ""}} {
  do_worth "worth" "USD" $nick $chan $text
}
proc msg:worthusd {nick uhost handle text} {
  do_worth "worth" "USD" $nick "PRIVATE" $text
}
proc pub:wortheur {nick host handle chan {text ""}} {
  do_worth "worth" "EUR" $nick $chan $text
}
proc msg:wortheur {nick uhost handle text} {
  do_worth "worth" "EUR" $nick "PRIVATE" $text
}

bind msg - !calc msg:calcusd
bind pub - !calc pub:calcusd
bind msg - !calcusd msg:calcusd
bind pub - !calcusd pub:calcusd
bind msg - !calceur msg:calceur
bind pub - !calceur pub:calceur

lappend axeircbot_command_fr { {!calceur & !calcusd} {Gain de minage} }
lappend axeircbot_command_en { {!calceur & !calcusd} {Mining earnings} }

bind msg - !diff msg:diff
bind pub - !diff pub:diff

lappend axeircbot_command_fr { {!diff} {Difficulté} }
lappend axeircbot_command_en { {!diff} {Difficulty} }

bind msg - !marketcap msg:marketcapusd
bind pub - !marketcap pub:marketcapusd
bind msg - !marketcapusd msg:marketcapusd
bind pub - !marketcapusd pub:marketcapusd
bind msg - !marketcapeur msg:marketcapeur
bind pub - !marketcapeur pub:marketcapeur
bind msg - !marketcapeuro msg:marketcapeur
bind pub - !marketcapeuro pub:marketcapeur

lappend axeircbot_command_fr { {!marketcapeur & !marketcapusd} {Capitalisation du March�} }
lappend axeircbot_command_en { {!marketcapeur & !marketcapusd} {Market Capitalizations} }

bind msg - !mnstats msg:mnstatsusd
bind pub - !mnstats pub:mnstatsusd
bind msg - !mnstatsusd msg:mnstatsusd
bind pub - !mnstatsusd pub:mnstatsusd
bind msg - !mnstatseur msg:mnstatseur
bind pub - !mnstatseur pub:mnstatseur
bind msg - !mnstatseuro msg:mnstatseur
bind pub - !mnstatseuro pub:mnstatseur

lappend axeircbot_command_fr { {!mnstatseur & !mnstatsusd} {Statistiques Masternodes} }
lappend axeircbot_command_en { {!mnstatseur & !mnstatsusd} {Masternode Statistics} }

bind msg - !mnwortheuro msg:mnwortheur
bind pub - !mnwortheuro pub:mnwortheur
bind msg - !mnwortheur msg:mnwortheur
bind pub - !mnwortheur pub:mnwortheur
bind msg - !mnvaleur msg:mnwortheur
bind pub - !mnvaleur pub:mnwortheur
bind msg - !mnworth msg:mnworthusd
bind pub - !mnworth pub:mnworthusd
bind msg - !mnworthusd msg:mnworthusd
bind pub - !mnworthusd pub:mnworthusd
bind msg - !mnvaleurusd msg:mnworthusd
bind pub - !mnvaleurusd pub:mnworthusd
bind msg - !mnv msg:mnwortheur
bind pub - !mnv pub:mnwortheur
bind msg - !mnw msg:mnworthusd
bind pub - !mnw pub:mnworthusd

lappend axeircbot_command_fr { {!mnvaleureur, !mnv, !mnvaleurusd & !mnw} {Gain Masternodes} }
lappend axeircbot_command_en { {!mnwortheur, !mnv, !mnworthusd & !mnw} {Masternode worth} }

bind msg - !wortheuro msg:wortheur
bind pub - !wortheuro pub:wortheur
bind msg - !wortheur msg:wortheur
bind pub - !wortheur pub:wortheur
bind msg - !valeur msg:wortheur
bind pub - !valeur pub:wortheur
bind msg - !v msg:wortheur
bind pub - !v pub:wortheur
bind msg - !valeureur msg:wortheur
bind pub - !valeureur pub:wortheur
bind msg - !worth msg:worthusd
bind pub - !worth pub:worthusd
bind msg - !worthusd msg:worthusd
bind pub - !worthusd pub:worthusd
bind msg - !valeurusd msg:worthusd
bind pub - !valeurusd pub:worthusd
bind msg - !w msg:worthusd
bind pub - !w pub:worthusd

lappend axeircbot_command_fr { {!valeureur, !v, !valeurusd & !w} {Prix} }
lappend axeircbot_command_en { {!wortheur, !v, !worthusd & !w} {Price} }

putlog "++ $::axeircbot_worth_script v$axeircbot_worth_subversion loaded!"
