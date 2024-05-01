#!/bin/bash

# Auto suspend and wake-up script
#
# Puts the computer on standby and automatically wakes it up at specified time
#
# Written by Romke van der Meulen <redge.online@gmail.com>
# Minor mods fossfreedom for AskUbuntu
#
# Takes a 24hour time HH:MM as its argument
# Example:
# suspend_until 9:30
# suspend_until 18:45
# second parameter will set user idle time consideration
# ------------------------------------------------------

# Argument check
if [ $# -lt 1 ]; then
    current_time=$(date)
    echo "${current_time}|Usage: suspend_until HH:MM"
    exit
fi

# declarations
declare -i num_active=0 #variable to keep track of active users
DISPLAY=:0

# set idle limit if not provided
declare -i idle_limit=60
if [[ -n $2 ]]
then
    idle_limit=$2    
    echo "${current_time}|idle limit set to [${idle_limit}]."
fi

# Exit if user is active in last 15 minutes
#****** Checkusers *********
# Use who to get list of users
#  then use who again to get user DISPLAY
#THIS SECTION DOES NOT WORK!!!!
#  NEEDS xprintidle
#for user in $(/usr/bin/who|/usr/bin/awk '{print $1}')
#do
#    # get display for user
#    udisplay=$(/usr/bin/who|grep ${user}|/usr/bin/awk '{print $2}'|grep '^:')
#    # get user idle time. 
#    milli_idle=$(sudo -u $user env DISPLAY=${udisplay} xprintidle)
#    # Convert milliseconds to minutes
#    minute_idle=$((milli_idle/60000))
#    # get current time for log
#    current_time=$(date)
#    if [[ $minute_idle -lt $idle_limit ]]
#    then
##        dbus_out=$(export DISPLAY=:0 && dbus-send --print-reply --dest=org.gnome.Mutter.IdleMonitor /org/gnome/Mutter/IdleMonitor/Core org.gnome.Mutter.IdleMonitor.GetIdletime)
##        echo $dbus_out
#        echo "${current_time}|$user active ${minute_idle} minutes ago. Idle limit[${idle_limit}]. Will not shutdown."
#        num_active=${num_active}+1
#       # echo "${current_time}|$user active ${minute_idle} minutes ago. Idle limit[${idle_limit}]. Exiting."
#        #exit 0 
#    else
#        echo "${current_time}|$user active ${minute_idle} minutes ago. Idle limit[${idle_limit}]."
#    fi
#done
#****** END Check users *********

#****** Check pts users *********
#current time
export curr_sec=$(date +%s)   

#last file pts activity seconds
LAST_PTS_FILE=$(ls -t /dev/pts|head -n1)
last_pts_sec=$(date +%s -r /dev/pts/${LAST_PTS_FILE})  
#calculate time from last activity
pts_elapsed_sec=$((curr_sec - last_pts_sec))
pts_elapsed_min=$((pts_elapsed_sec/60))

# Exit if pts user active within idle limit
if [[ $pts_elapsed_min -lt $idle_limit ]]
then
    current_time=$(date)
    echo "${current_time}| /dev/pts/${LAST_PTS_FILE} active ${pts_elapsed_min} minutes ago. Will not shutdown."
    num_active=${num_active}+1
    #dce echo "${current_time}| /dev/pts/${LAST_PTS_FILE} active ${pts_elapsed_min} minutes ago. Exiting"
    #dce exit 0 
fi
#****** END Check pts users *********

# Check last samba access
# get last file 
export SAMBA_DIR="/var/log/samba"
# identify last updated file in the samba directory
export LAST_SFILE=$(ls -t /var/log/samba|grep -v log.smb|grep -v log.nmbd|head -n1)
export last_samba_sec=$(date +%s -r ${SAMBA_DIR}/${LAST_SFILE})
curr_sec=$(date +%s)
samba_elapsed=$((curr_sec - last_samba_sec))
samba_elapsed_min=$(($samba_elapsed/60))

# Exit if samba active within idle_limit
if [[ $samba_elapsed_min -lt $idle_limit ]]
then
    current_time=$(date)
    echo "${current_time}|${LAST_SFILE} samba active ${samba_elapsed_min} minutes ago. Will not shutdown."
    num_active=${num_active}+1
    #dce echo "${current_time}|${LAST_SFILE} samba active ${samba_elapsed_min} minutes ago. Exiting"
    #dce exit 0 
fi

#Exit if there are active users
if [[ $num_active -gt 0 ]]
then
    echo "${current_time}|There are ${num_active} active users. Will not shutdown."
    exit 0
fi

# Check whether specified time today or tomorrow
DESIRED=$((`date +%s -d "$1"`))
NOW=$((`date +%s`))
if [ $DESIRED -lt $NOW ]; then
    DESIRED=$((`date +%s -d "$1"` + 24*60*60))
fi

# Kill rtcwake if already running
sudo killall rtcwake

# Set RTC wakeup time
# N.B. change "mem" for the suspend option
# find this by "man rtcwake"
sudo rtcwake -l -m mem -t $DESIRED &

# feedback
current_time=$(date)
echo "${current_time}|Suspending..."

# give rtcwake some time to make its stuff
sleep 2

# then suspend
# N.B. dont usually require this bit
#sudo pm-suspend

# Any commands you want to launch after wakeup can be placed here
# Remember: sudo may have expired by now

# Wake up with monitor enabled N.B. change "on" for "off" if 
# you want the monitor to be disabled on wake
# Wake without monitor. --DCE
xset dpms force off

# and a fresh console
#clear
#echo "Good morning!"
