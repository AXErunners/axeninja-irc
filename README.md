# AXE Ninja IRC Bot Script (axeninja-irc)

This is part of what makes the AXE Ninja monitoring application.
It contains:
- TCP eggdrop scripts for an IRC bot

## Requirement:
* Eggdrop bot (v1.8)
* tcl 8.6 with mysqltcl 3.052 and tcl-tls 1.6
* A AXE Ninja Front-End public API (axeninja-fe).
* A AXE Ninja Database on same machine on localhost (axeninja-db).

## Install:
* Import database structure in your MySQL server
* Go to the root of your eggdrop bot user (ex: cd /home/axeninja2/irc/)
* Get latest code from github:
```shell
git clone https://github.com/elbereth/axeninja-irc.git
```
* Add the following lines to your eggdrop.conf (or whatever main eggdrop conf file you use for your bot):
```
# AXE IRC Bot settings

#  MySQL (axeninja-db)
set axeircbot_mysqluser "axeircbot"
set axeircbot_mysqlpass "somerandompassword"
set axeircbot_mysqldb "axeninja"

#  Path to scripts
set axeircbot_dir "/home/axeninja2/irc/axeninja-irc/"

#  Message length limit
set axeircbot_msglenlimit 442

#  If you want to use the Twitter announces
#   MySQL
set axeircbot_twitter_mysqluser "axeirctwitter"
set axeircbot_twitter_mysqlpass "someotherrandompassword"
#   Twitter nickname
set axeircbot_twitter_screenname "@axerunners"
#   Update script path (needs tweet-php)
set axeircbot_twitter_updatescript "/home/axeninja2/irc/axeircbot/helpers/updatetwitter"

# AXE IRC Bot bootstrap
source /home/axeninja2/irc/axeircbot/axeircbot.tcl
```
* Configure the updatetwitter helper script in ./helpers/ folder by copying updatetwitter.config.inc.php.sample to updatetwitter.config.inc.php and setting up the values as needed.

_Based on Dash Ninja by Alexandre (aka elbereth) Devilliers
