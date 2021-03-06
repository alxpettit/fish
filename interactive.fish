# FISH config file specifically for interactive mode
# Copyleft (C) Alexandria Pettit, GNU GPLv3


# Dummy function for disabling FISH greeting
function fish_greeting
end

### Helpful FISH abbreviations

set -g fish_user_abbreviations
abbr -a s sudo
abbr -a e exit
abbr -a q exit
abbr -a ... ../..
abbr -a .... ../../..
abbr -a ..... ../../../..
abbr -a ...... ../../../../..
abbr -a dds 'dd conv=fsync bs=1M status=progress'
abbr -a ytdl youtube-dl

# aliases permit tab suggestions to work with the shorter version
alias jctl journalctl
alias sctl systemctl

# Makes it so prompt_pwd isn't so aggressive with its abbreviating paths
set fish_prompt_pwd_dir_length 128

### Our custom hex color definitions

set hexcolor_cute_purple C300FF
set hexcolor_firey_orange FF8800
set hexcolor_cute_pink FB57D0

### Adjustable color profile

set fish_color_cwd brblue
set fish_color_hostname $hexcolor_cute_purple
set fish_color_delimiter bryellow
set fish_color_username $hexcolor_cute_pink
set fish_color_time brcyan
set fish_color_time_root brred
set fish_color_username_root brred
set fish_color_cwd_root brred
set fish_color_status bryellow
set fish_color_percent_good brgreen
set fish_color_percent_bad $hexcolor_firey_orange
set fish_color_percent_worst brred
set fish_color_status_zero brgreen
set fish_color_status_nonzero brred 
set fish_color_mscount magenta
set fish_notify_duration_ms 5000

# Our suffixes for root and non-root respectively
set fish_suffix_root '#'
set fish_suffix_user '$'

set fish_send_notification 1
set fish_notification_threshold 10000

# Offers option to override specific variables without rewriting this file.
# I added this so my friends would be able to use my config.fish
# and override features without editing this file and having to worry about merging updates.
if test -e "/etc/fish/interactive-override.fish"
    source "/etc/fish/interactive-override.fish"
end

if test -e "/usr/bin/thefuck"
    thefuck --alias | source 
end

# If this returns 0, it's in the background
function window_is_in_background --description "Test for window focus"
    if test (xdotool getwindowfocus) = "$WINDOWID"
        # 1 = false in shell-land.
        # Why? Because we like to confuse people.
        return 1
    else
        return 0
    end
end

function fish_prompt --description "Write out the prompt"
    # Store status of last user-executed command
    # before it's overwritten.
    set -l last_status $status


    # If desired, send notification when command
    # takes longer than a certain amount of time to complete 
    if test -e /usr/bin/notify-send -a "$fish_send_notification" = "1" -a \
    -n "$DISPLAY"
        if test "$CMD_DURATION" -gt "$fish_notification_threshold"
            if window_is_in_background
                notify-send -t $fish_notify_duration_ms -i utilities-terminal 'Process complete' "$history[1]"
            end
        end
    end

    # Initialize suffix variable (controls whether we're using $ or #)
    set -l suffix
    
     # Get percentage of free space on disk
    set -l rpcnt (perl -e 'use Filesys::Df;print df("/")->{per};')   

    ### Initialize dynamic color vars

    # Working directory color changes based on whether we're root
    set -l color_cwd
    # Username color changes based on whether we're root
    set -l color_username
    # Status color changed based on whether status is zero
    set -l color_status
    # Disk percentage color changes based on how full the disk is
    set -l color_percent
    # Time color changes based on whether we're root
    set -l color_time

    ### Dynamic garbage -- code to change colors and stuff based on various conditions
   
    # Configure colors and suffix symbol based on whether or not we're root 
    switch "$USER"
        case root toor
            set color_cwd $fish_color_cwd_root
            set color_username $fish_color_username_root
            set color_time $fish_color_time_root
            set suffix $fish_suffix_root
        case '*'
            set color_cwd $fish_color_cwd
            set color_username $fish_color_username 
            set suffix $fish_suffix_user
            set color_time $fish_color_time
    end
    
    # Change status color based on whether it was zero
    if test $last_status -eq 0
        set color_status $fish_color_status_zero
    else
        set color_status $fish_color_status_nonzero
    end
    
    # Set disk percentage color based on how full disk is
    if test $rpcnt -gt 90
        set color_percent $fish_color_percent_worst
    else if test $rpcnt -gt 50
        set color_percent $fish_color_percent_bad
    else
        set color_percent $fish_color_percent_good
    end
    
    # Initialize a bunch of little variables to display
    set -l wd (prompt_pwd)
    set -l host (hostname)
    set -l time (date '+%H:%M:%S')

    ### The following creates a set of variables containing color characters
    ### These variables are extremely abbreviated so that our final prompt line instructions are vaguely readable and not too verbose

    # Color for current user
    set Cusr (set_color $color_username)
    # Color for delimiters and the suffix
    set Cdlm (set_color $fish_color_delimiter)
    # Color for status of previous command
    set Cstat (set_color $color_status)
    # Normal color, for end of prompt
    set Cnorm (set_color normal)
    # Color for hostname
    set Chost (set_color $fish_color_hostname)
    # Color for current working directory
    set Ccwd (set_color $color_cwd)
    # Color for percentage of / taken up
    set Cpcnt (set_color $color_percent)
    # Color for time
    set Ctime (set_color $color_time)   


    ### Endgame: it's finally time for us to print our prompt line!
    
    ### Line 1: Makes something of a format like "user@hostname /some/path (status) (drive percentage full)"
    
    echo -s $Cusr "$USER" $Cdlm '@' $Chost $host ' ' $Ccwd $wd $Cdlm" ("$Ctime $time \
    $Cdlm") (" $Cstat $last_status $Cdlm ') (' $Cpcnt $rpcnt '%' $Cdlm ')'
    
    ### Line 2: Just prints the suffix (# or $) and normalizes font color for user input
    
    echo -s $Cdlm $suffix  $Cnorm ' '
end

# Optional: add additional right-justified elements to terminal prompt
function fish_right_prompt
    set Cms (set_color $fish_color_mscount)
    set Cnorm (set_color normal)
    echo -s $Cms $CMD_DURATION $Cnorm
end
