#!/bin/grep ^#:

#:------------------------------------------------------------------------
#: Auther: Sheraz.Ahmed@vaival.com
#: Copyright 2020 Sheraz Ahmed ( sheraz.ahmed@vaival.com )
#: 
#: This program is free software: you can redistribute it and/or modify
#: 
#: Deploy:
#:  wget -O ~/.bashrc_fancy_prompt_v2.sh https://raw.githubusercontent.com/sherazahmedvaival/ubuntu/main/.bashrc_fancy_prompt_v2.sh
#:  chmod +x ~/.bashrc_fancy_prompt_v2.sh
#:  echo "source ~/.bashrc_fancy_prompt_v2.sh" >> ~/.bashrc
#:  
#:
#:  Remove: ("source ~/.bashrc_fancy_prompt..." line)
#:      vi ~/.bashrc
#:
#:------------------------------------------------------------------------

PROMPT_COMMAND=fancy-prompts-command

#trap 'fancy-prompts-command' WINCH

_prompt-fill() {
    local char=${2}
    for i in $(seq $1); do echo -n "$char" ;done
}

fancy-prompts-command() {
    
    local hbar="─" vbar="│" tl_corn="┌" tr_corn="┐" bl_corn="└" br_corn="┘"

    BLACK=$(tput setaf 0)
    BLACK_BG=$(tput setab 0)
    RED=$(tput setaf 1)
    RED_BG=$(tput setab 1)
    GREEN=$(tput setaf 2)
    GREEN_BG=$(tput setab 2)
    LIME_YELLOW=$(tput setaf 190)
    LIME_YELLOW_BG=$(tput setab 190)
    YELLOW=$(tput setaf 3)
    YELLOW_BG=$(tput setab 3)
    POWDER_BLUE=$(tput setaf 153)
    POWDER_BLUE_BG=$(tput setab 153)
    BLUE=$(tput setaf 4)
    BLUE_BG=$(tput setab 4)
    MAGENTA=$(tput setaf 5)
    MAGENTA_BG=$(tput setab 5)
    CYAN=$(tput setaf 6)
    CYAN_BG=$(tput setab 6)
    WHITE=$(tput setaf 7)
    WHITE_BG=$(tput setab 7)
    BRIGHT=$(tput bold)
    NORMAL=$(tput sgr0)
    BLINK=$(tput blink)
    REVERSE=$(tput smso)
    UNDERLINE=$(tput smul)

    # Color table
    # for c in {0..255}; do tput setaf $c; tput setaf $c | cat -v; echo =$c; done
    # for c in {0..255}; do tput setaf $c; tput setaf $c | cat -v; echo -e " "; done

    local e=$(printf "\e[")
    local   black="\[${e}0;30m\]"     blue="\[${e}0;34m\]"      green="\[${e}0;32m\]"
    local    cyan="\[${e}0;36m\]"      red="\[${e}0;31m\]"     purple="\[${e}0;35m\]"
    # local   brown="\[${e}0;33m\]"  lt_gray="\[${e}0;37m\]"    dk_gray="\[${e}1;30m\]"
    # local   brown="\[${e}0;33m\]"  lt_gray="\[${e}0;37m\]"    dk_gray="\[${e}38;5;242m\]"
    local   brown="\[${e}0;33m\]"  lt_gray="\[${e}0;37m\]"    dk_gray="\[${e}90m\]"
    local lt_blue="\[${e}1;34m\]" lt_green="\[${e}1;32m\]"    lt_cyan="\[${e}1;36m\]"
    local  lt_red="\[${e}1;31m\]"  magenta="\[${e}1;35m\]"     yellow="\[${e}1;33m\]"
    local   white="\[${e}1;37m\]"  rev_red="\[${e}0;7;31m\]"

    # no color
    local nc="\[${e}0m\]"

    local lb="❲" rb="❳"

    local name_co=$green prom_co=$cyan line_co=$dk_gray  date_co=$dk_gray
    local time_co=$dk_gray   host_co=$green  path_co=$cyan title_co=$lt_red at_co=$green

    local load_1_co="\[${e}97m"
    local load_5_co="\[${e}36m"
    local load_15_co="\[${e}33m"

    local name=$(id -nu)
    local host=$(hostname)

    local time_bar=$(date +"%I:%M:%S %P")
    local time_len=${#time_bar}

    local date_bar=$(date +"%a, %B %d")
    local date_len=${#date_bar}

    local date_time_bar=$(date +"%a, %B %d %I:%M:%S %P")
    local date_time_len=${#date_bar}

    local sys_load_avg_bar=$(uptime | cut -d ":" -f5)
    local sys_load_avg_len=${#sys_load_avg_bar}
    
    local load_1_bar=$(echo $sys_load_avg_bar | cut -d "," -f1)
    local load_5_bar=$(echo $sys_load_avg_bar | cut -d "," -f2)
    local load_15_bar=$(echo $sys_load_avg_bar | cut -d "," -f3)

    local load_avg_bar="$lb Load AVG: $load_1_bar $load_5_bar $load_15_bar $rb"

    local name_block="${line_co}${name_co}${name}${nc}${at_co}@${host_co}${host}${line_co}"
    local path_block="${line_co}${path_co}${PWD}${line_co}"
    local time_block="${line_co}${time_co}${time_bar}${line_co}"
    local date_block="${line_co}${date_co}${date_bar}${line_co}"
    local date_time_block="${line_co}${date_co}${date_time_bar}${line_co}"
    local load_avg_block="${line_co}Load AVG: ${load_1_co}${load_1_bar} ${load_5_co}${load_5_bar} ${load_15_co}${load_15_bar}${line_co}"


    local _prompt_1_bar="${line_co}  ▓▒░ ${date_time_block}\n"
    local _prompt_2_bar="${line_co}┌─▓▒░ ${load_avg_block}\n"
    local _prompt_3_bar="${line_co}│ ▓▒░ ${name_block}${white}:${path_block}\n"
    local _prompt_4_bar="${line_co}│${nc}\n"
    # local _prompt_5_bar="${line_co}└─⟩${prom_co}🤖${nc}"
    # local _prompt_5_bar="${line_co}└─ ⟩${prom_co}🧞‍♂️${nc}"
    # local _prompt_5_bar="${line_co}└─ 🧜‍♀️${nc}"
    # local _prompt_5_bar="${line_co}└─${nc} 🐧 "

    # local _prompt_5_bar="${line_co}└─${prom_co}${nc}💲 "
    # local _prompt_5_bar="${line_co}└─${prom_co}#${nc} "
    local _prompt_5_bar="${line_co}└─＄${nc} "

    PS1="\n${_prompt_1_bar}${_prompt_2_bar}${_prompt_3_bar}${_prompt_4_bar}${_prompt_5_bar}"

}
