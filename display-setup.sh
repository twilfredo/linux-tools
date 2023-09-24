#!/bin/bash
# Switch between workstation monitor setup and gaming setup

primary="DP-1"
primary_cfg="3840x1600@143.998"
secondary="DP-3"
secondary_cfg="2560x1440@143.912"
tv="HDMI-1"
tv_cfg="3840x2160@120.000"
# Audio outputs by name
logitech_speaker="Starship/Matisse HD Audio Controller Analog Stereo"
tv_soundbar="Navi 21/23 HDMI/DP Audio Controller Digital Stereo (HDMI 4)"

get_wpctl_sink_id_logitech_speaker() {
    wpctl status |  awk '/Sinks:/{flag=1; next} /Sink endpoints:/{flag=0} flag' | grep "$logitech_speaker" | grep -o '[0-9][0-9]\+\.' | awk -F '.' '{print $1}'
}

get_wpctl_sink_id_tv() {
    wpctl status | awk '/Sinks:/{flag=1; next} /Sink endpoints:/{flag=0} flag' | grep "$tv_soundbar" | grep -o '[0-9][0-9]\+\.' | awk -F '.' '{print $1}'
}

set_workstation() {
   # Secondary positioned at [0, 0] far left.
   # Primary positioned at [1440, 270] respective to [0, 0] of secondary.
   gnome-monitor-config set -LM "$secondary" -m "$secondary_cfg" -t left -LpM "$primary" -m "$primary_cfg" -x 1440 -y 270 -t normal
   sleep 1
   #re-route audio sink
   sink_id=$(get_wpctl_sink_id_logitech_speaker)
   if [ -z "$sink_id" ]; then
       echo "Error: sink not detected for $logitech_speaker"
       return
   fi
   wpctl set-default $sink_id
}

set_media() {
   gnome-monitor-config set -LpM "$tv" -t normal -m "$tv_cfg" -s 2
   sleep 1
   #re-route audio sink
   sink_id=$(get_wpctl_sink_id_tv)
   if [ -z "$sink_id" ]; then
       echo "Error: sink not detected for $tv_soundbar"
       return
   fi
   wpctl set-default $sink_id
}

launch_steam() {
   echo "Launching steam in big picture mode"
   #kill steam if it was running
   pkill steam
   nohup steam -bigpicture &
   steam_pid=$!
   wait "$steam_pid"
   set_workstation
}

# Check that we are on Wayland
if [ "$XDG_SESSION_TYPE" != "wayland" ]; then
   echo "This script only supports wayland"
   exit 1
fi

# Check if the number of arguments is at least 1
if [ $# -ne 1 ]; then
   echo "Usage: $0 <mode>"
   echo "Supported modes are: media, workstation, game"
   exit 1
fi

if [ "$1" = "media" ]; then
   echo "Setting up monitors for media config"
   set_media
elif [ "$1" = "workstation" ]; then
   echo "Setting up monitors for workstation config"
   set_workstation
elif [ "$1" = "game" ]; then
   echo "Gaming time!"
    set_media
    launch_steam
else
  echo "Invalid argument"
  exit 1
fi 
