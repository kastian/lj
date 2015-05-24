#!/bin/bash

# lj - shell script for posting to livejournal

# Copyright 2015 #kstn

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.

### Global variables ###################################################
VERSION="0.9"
CONFIG_DIR="$HOME/.lj"
CONFIG_FILE="${CONFIG_DIR}/lj"
COOKIE="/tmp/lj_cookie"
LJ_FORM="/tmp/lj_form"
LOG="/tmp/lj_log"

### Bas config file ####################################################
CONFIG_BAS=$(cat <<EOF
# -*- mode: shell-script; -*-
# basic config for lj
# uncomment to use
USER_AGENT='Mozilla/5.0 (X11; Linux i686; rv:38.0) Gecko/20100101 Firefox/38.0' # Masking for browser - for i686
# USER_AGENT='Mozilla/5.0 (X11; Linux x86_64; rv:38.0) Gecko/20100101 Firefox/38.0' # Masking for browser - for x86_64
# LJ_USER="username"    # Default lj to post (only login)
# LJ_PASS="password"    # Default password. IMPORTANT - this is unsafe option
# LJ_SECURITY="private" # Default security (public, friends, private)
# LJ_ADULT="default"    # prop_adult_content (default, none, explicit)
# end of file
EOF
)

die()  { echo "$1" >&2 ; exit 1; }
ok()   { echo "$(tput hpa 70)[$(tput setf 2)OK$(tput setf 7)]" ; }
fail() { echo "$(tput hpa 70)[$(tput setf 4)FAIL$(tput setf 7)]"; exit 1; }

[[ "${EDITOR}" ]] || die "\$EDITOR is not set. Set it or run lj as 'EDITOR=\"emacs\" lj'"
# ### Parse command line args ############################################
if [[ "$1" ]]; then
    case "$1" in
	-c  | --config)
	    $EDITOR $CONFIG_FILE;
	    exit 0;
	    ;;
	-v | --version)
	    echo "lj ${VERSION}"
	    echo "Copyright (C) 2015 #kstn"
	    echo "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>"
	    echo "This is free software: you are free to change and redistribute it."
	    echo "There is NO WARRANTY, to the extent permitted by law."
	    exit 0;
	    ;;
	-h | --help )
	    echo "lj - shell script for posting to livejournal"
	    echo "Usage: lj [OPTION...]"
	    echo "  -c  --config     edit config file ($CONFIG_FILE)"
	    echo "  -h  --help       display this help and exit"
	    echo "  -v  --version    output version information and exit"
	    echo "lj home page: <https://github.com/kastian/lj>"
	    echo "Report bugs to: <https://github.com/kastian/lj/issues>"
	    exit 0;
	    ;;
	* )
	    echo "$0: unrecognized option '$1'";
	    echo "$0: use the --help option for more information";
	    exit 1
	    ;;
    esac
fi
### Check needed utilites ##############################################
[[ $(which curl 2>/dev/null) ]]         || die "Can't find curl. Install it"
[[ $(which mktemp 2>/dev/null) ]]       || die "Can't find mktemp. Install it"
[[ $(which xmllint 2>/dev/null) ]]      || die "Can't find xmllint. Install it"
### Check config dir and make if not ###################################
if [[ ! -d "$CONFIG_DIR" ]]; then
    mkdir "$CONFIG_DIR"                 || die "Can't make $CONFIG_DIR"
fi
### Check config file and make if not ##################################
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "$CONFIG_BAS" > "$CONFIG_FILE" || die "Can't make config file ($CONFIG_FILE)"
    chmod 600 "$CONFIG_FILE"            || die "Can't chmod config file"
fi
### load config ########################################################
. "$CONFIG_FILE"
### make masked pass variable ##########################################
MASK=$(echo "$LJ_PASS" | tr [:print:] '*')
### get login ##########################################################
while (true); do
    read -p "LJ [$LJ_USER]: " VAR
    [[ "$VAR" ]] && LJ_USER="$VAR"
    [[ "$LJ_USER" ]] && break
done
### get password #######################################################
while (true); do
    read -s -p "Password [$MASK]: " VAR
    if [[ "$VAR" ]]; then
	LJ_PASS="$VAR"
	MASK=$(echo "$LJ_PASS" | tr [:print:] '*')
    fi
    echo ""
    [[ "$LJ_PASS" ]] && break
done
### get subject ########################################################
IFS="\n" read -p "Subject: " LJ_SUBJECT

### get post ###########################################################
TMP_FILE=$(mktemp)
$EDITOR $TMP_FILE
LJ_POST=$(cat $TMP_FILE)

IFS="\n" read -p "Mood: " LJ_MOOD
IFS="\n" read -p "Music: " LJ_MUSIC
IFS="\n" read -p "Location: " LJ_LOCATION
IFS="\n" read -p "Tag (comma separated): " LJ_TAGS

while (true); do
    read -n1 -p "Security (1 - public, 2 - friends, 3 - private) [$LJ_SECURITY]: " VAR
    case "$VAR" in
	1) LJ_SECURITY="public"  ;;
	2) LJ_SECURITY="friends" ;;
	3) LJ_SECURITY="private" ;;
    esac
    [[ "$LJ_SECURITY" ]] && break
done

### get time and date (last of all!) ###################################
LJ_TIME=$(date '+%H:%M')	# 11:09
LJ_DATE=$(date '+%m/%d/%Y')	# 10/27/2014

### display post for check #############################################
clear
echo "LJ:       $LJ_USER"
echo "Password: $MASK"
echo "Date:     $LJ_DATE"
echo "Time:     $LJ_TIME"
echo "Security: $LJ_SECURITY"
echo ""
echo "Subject:  $LJ_SUBJECT"
echo "$LJ_POST"
echo ""
echo "Tags:     $LJ_TAGS"
echo "Mood:     $LJ_MOOD"
echo "Music:    $LJ_MUSIC"
echo "Location: $LJ_LOCATION"

echo ""
read -n 1 -p "Is all right? [y/n]: " VAR
echo ""

### save post ##########################################################
if [[ "$VAR" != "n" && "$VAR" != "N" ]] ; then
    LJ_FILE="${CONFIG_DIR}/post_$(date '+%s')"
    cat <<EOF > "$LJ_FILE"
LJ_USER='$LJ_USER'
LJ_DATE='$LJ_DATE'
LJ_TIME='$LJ_TIME'
LJ_SECURITY='$LJ_SECURITY'
LJ_SUBJECT='$LJ_SUBJECT'
LJ_TAGS='$LJ_TAGS'
LJ_POST='$LJ_POST'
EOF
    echo "Post saved to $LJ_FILE"
fi

# get cookie
echo -n "Get cookie..."
curl -s -v -A "$USER_AGENT" \
     -b "$COOKIE" -c "$COOKIE" \
     -d "ret=1" \
     -d "user=$LJ_USER" \
     -d "password=$LJ_PASS" \
     --data-urlencode "action:login=" \
     -e "http://www.livejournal.com/" \
     https://www.livejournal.com/login.bml > /dev/null 2>"$LOG"

# check answer
(( $(grep -E '^< HTTP' "$LOG" | cut -d ' ' -f 3) == 200)) && ok || fail

# get lj_form_auth
echo -n "Get auth..."
curl -s -v -A "$USER_AGENT" \
     -b "$COOKIE" -c "$COOKIE" \
     -e "http://www.livejournal.com/" \
     http://www.livejournal.com/update.bml > "$LJ_FORM" 2>"$LOG"

# check answer
(( $(grep -E '^< HTTP' "$LOG" | cut -d ' ' -f 3) == 200)) && ok || fail

LJ_FORM_AUTH=$(xmllint --html --xpath 'string(//input[@name="lj_form_auth"]/@value)' "$LJ_FORM" 2>/dev/null)

# send post
echo -n "Send post..."
curl -s -v -A "$USER_AGENT" \
     -b "$COOKIE" -c "$COOKIE" \
     -e "http://www.livejournal.com/update.bml" \
     -d "lj_form_auth=$LJ_FORM_AUTH" \
     -d "rte_on=0" \
     -d "date_diff=1" \
     --data-urlencode "date_format=%M/%D/%Y" \
     -d "postas=remote" \
     -d "user=" \
     -d "password=" \
     -d "postto=journal" \
     -d "community=" \
     -d "altcommunity=" \
     --data-urlencode "date=$LJ_DATE" \
     --data-urlencode "time=$LJ_TIME" \
     -d "custom_time=0" \
     -d "timezone=300" \
     -d "prop_picture_keyword=" \
     --data-urlencode "subject=$LJ_SUBJECT" \
     --data-urlencode "body=$LJ_POST" \
     --data-urlencode "prop_taglist=$LJ_TAGS" \
     -d "prop_current_moodid=0" \
     --data-urlencode "prop_current_mood=$LJ_MOOD" \
     --data-urlencode "prop_current_music=$LJ_MUSIC" \
     --data-urlencode "prop_current_location=$LJ_LOCATION" \
     -d "prop_adult_content=default" \
     -d "comment_settings=default" \
     -d "prop_opt_screening=" \
     -d "security=$LJ_SECURITY" \
     --data-urlencode "action:update=1" \
     -d "nojs=1" \
     http://www.livejournal.com/update.bml > /dev/null 2>"$LOG"
ok

# clean up
echo -n "Clean up..."
[[ "$COOKIE"  ]] && rm "$COOKIE"
[[ "$LJ_FORM" ]] && rm "$LJ_FORM"
[[ "$LOG"     ]] && rm "$LOG"
ok
