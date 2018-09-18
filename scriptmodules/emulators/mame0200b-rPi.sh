#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

#
# Installation Instructions
# =========================
# 
# SSH into your Raspberry Pi
# Run the following commands:
# 
#   cd ~/RetroPie-Setup/scriptmodules/emulators/
#   wget https://raw.githubusercontent.com/GeorgeMcMullen/RetroPie-Setup/master/scriptmodules/emulators/mame0200b-rPi.sh
#   cd
#   sudo ~/RetroPie-Setup/retropie_setup.sh
# 
# In the RetroPie setup program do the following:
# 
#   Select "P" to Manage packages
#   Select "e" to Manage experimental packages
#   Select "mame0200b-rPi"
#   Select "B" to Install from binary
# 
# Then exit the RetroPie setup program.
# Finally, either restart Emulation Station or reboot the machine.
# 
# Place the ROMs in the following directory:
# 
#   /home/pi/RetroPie/roms/mame-mame0200b-rPi
#
# On a Raspberry Pi 3 the games can still run rather slowly. When launching,
# hit any button to get into the emulator configuration menu and do the following:
# 
#   Hit "4" to Select video mode for mame0200b-rPi
#   Select CEA-1 (640x480 @ 60Hz 4:3, clock:25MHz progressive
#
# TODO: This script does not do any configuration of the existing theme. MAME will show up as its own entry but without any graphics.
#

rp_module_id="mame0200b-rPi"
rp_module_desc="MAME v0.200b-rPi"
rp_module_help="ROM Extension: .zip\n\nCopy your MAME v0.200b-rPi roms to either $romdir/mame-mame0200b-rPi or\n$romdir/arcade"
rp_module_licence="GPL2 https://raw.githubusercontent.com/mamedev/mame/master/LICENSE.md"
rp_module_section="exp"
rp_module_flags="!x11 !mali"

debug=0

## @fn depends_mame0200b-rPi()
## @brief Installs the required dependencies
function depends_mame0200b-rPi() {
    getDepends libsdl2-ttf-2.0-0
}

## @fn install_bin_mame0200b-rPi()
## @brief Installs the mame0200b-rPi binary by downloading and extracting it
function install_bin_mame0200b-rPi() {
    local mame="mame0200b-rPi"

    if [[ "$debug" -eq "1" ]]; then
        unzip -n "/home/pi/Downloads/$mame.zip" -d "$md_inst"
    else
        # Download and unzip the binary file 
        # TODO: Test downloadAndExtract
        # downloadAndExtract "https://github.com/GeorgeMcMullen/mame/releases/download/mame0200/mame0200b-rPi.zip" "$md_inst"
    
        # TODO: Check for error and exit
        # fatalError "Unable to download and extract."
    
        # Old download and extract code
        wget "https://github.com/GeorgeMcMullen/mame/releases/download/mame0200/mame0200b-rPi.zip" -O "$md_inst/$mame.zip"
        unzip -n "$md_inst/$mame.zip" -d "$md_inst"
        rm "$md_inst/$mame.zip"
        # End: Old download and extract code
    fi
    
    # The zip file gets unzipped into a subdirectory, so we need to move that back out
    mv "$md_inst/$mame"/* "$md_inst" 
    rmdir "$md_inst/$mame" 
    
    # This will give everyone permission to read the directories where MAME is
    find "$md_inst" -type d -exec chmod a+rx {} \;
}

## @fn remove_mame0200b-rPi()
## @brief Uninstalls mame0200-rPi by deleting the binary and configuration directories
function remove_mame0200b-rPi() {
    # Optionally you can remove configureation directories here
    local system="mame-mame0200b-rPi"
    rmDirExists "$md_inst"
    rmDirExists "$md_conf_root/$system/"
    rm /home/pi/.mame
    delEmulator "$md_id" "arcade"
    delEmulator "$md_id" "$system"
}

## @fn configure_mame0200b-rPi()
## @brief Creates the rom directories and configuration files for mame0200-rPi
function configure_mame0200b-rPi() {
    local system="mame-mame0200b-rPi"
    mkRomDir "arcade"
    mkRomDir "$system"
    mkRomDir "$system/artwork"
    mkRomDir "$system/samples"

    if [[ "$md_mode" == "install" ]]; then
        #mkdir -p "$md_conf_root/$system/"{hi,memcard}
        mkdir -p "$md_conf_root/$system/"{cfg,nvram,inp,sta,snap,diff,comments}
        
        if [[ ! -e "/home/pi/.mame" ]]; then
            # Make a symbolic link for the MAME ini directory
            ln -s $md_conf_root/$system/ /home/pi/.mame
        fi

        # Create a new INI file
        local config="$(mktemp)"
        "$md_inst/mame" -showconfig >"$config"

        iniConfig " " "" "$config"
        iniSet "cfg_directory" "$md_conf_root/$system/cfg"
        iniSet "nvram_directory" "$md_conf_root/$system/nvram"
        iniSet "input_directory" "$md_conf_root/$system/inp"
        iniSet "state_directory" "$md_conf_root/$system/sta"
        iniSet "snapshot_directory" "$md_conf_root/$system/snap"
        iniSet "diff_directory" "$md_conf_root/$system/diff"
        iniSet "comment_directory" "$md_conf_root/$system/comments"
        iniSet "skip_gameinfo" "1"
        iniSet "artpath" "$romdir/$system/artwork"
        iniSet "samplepath" "$romdir/$system/samples;$romdir/arcade/samples"
        iniSet "rompath" "$romdir/$system;$romdir/arcade"

        iniSet "samplerate" "44100"

        copyDefaultConfig "$config" "$md_conf_root/$system/mame.ini"
        rm "$config"

        chown -R $user:$user "$md_conf_root/$system"
        chmod a+r "$md_conf_root/$system/mame.ini"
    fi

    addEmulator 0 "$md_id" "arcade" "$md_inst/mame %BASENAME%"
    addEmulator 1 "$md_id" "$system" "$md_inst/mame %BASENAME%"
    
    addSystem "arcade" "$rp_module_desc" ".zip"
    addSystem "$system" "$rp_module_desc" ".zip"
}

## @fn _add_system_mame0200b-rPi()
## @param fullname full name of system
## @param name short name of system
## @param path rom path
## @param extension file extensions to show
## @param command command to run
## @param platform name of platform (used by es for scraping)
## @param theme name of theme to use
## @brief Helper function for setESSystem() that adds a system entry for Emulation Station with the Mame theme.
function _add_system_mame0200b-rPi() {
    local fullname="$1"
    local name="$2"
    local path="$3"
    local extension="$4"
    local command="$5"
    local platform="arcade"
    local theme="mame"

    local conf="/etc/emulationstation/es_systems.cfg"
    mkdir -p "/etc/emulationstation"
    if [[ ! -f "$conf" ]]; then
        echo "<systemList />" >"$conf"
    fi

    cp "$conf" "$conf.bak"
    if [[ $(xmlstarlet sel -t -v "count(/systemList/system[name='$name'])" "$conf") -eq 0 ]]; then
        xmlstarlet ed -L -s "/systemList" -t elem -n "system" -v "" \
            -s "/systemList/system[last()]" -t elem -n "name" -v "$name" \
            -s "/systemList/system[last()]" -t elem -n "fullname" -v "$fullname" \
            -s "/systemList/system[last()]" -t elem -n "path" -v "$path" \
            -s "/systemList/system[last()]" -t elem -n "extension" -v "$extension" \
            -s "/systemList/system[last()]" -t elem -n "command" -v "$command" \
            -s "/systemList/system[last()]" -t elem -n "platform" -v "$platform" \
            -s "/systemList/system[last()]" -t elem -n "theme" -v "$theme" \
            "$conf"
    else
        xmlstarlet ed -L \
            -u "/systemList/system[name='$name']/fullname" -v "$fullname" \
            -u "/systemList/system[name='$name']/path" -v "$path" \
            -u "/systemList/system[name='$name']/extension" -v "$extension" \
            -u "/systemList/system[name='$name']/command" -v "$command" \
            -u "/systemList/system[name='$name']/platform" -v "$platform" \
            -u "/systemList/system[name='$name']/theme" -v "$theme" \
            "$conf"
    fi

    _sort_systems_emulationstation "name"
}

## @fn _del_system_mame0200b-rPi()
## @param system system to delete
## @brief Helper function for delSystem() that deletes a system
## @details deletes mam0200b-rPi from all frontends.
function _del_system_mame0200b-rPi() {
    local fullname="$1"
    local name="$2"
    if [[ -f /etc/emulationstation/es_systems.cfg ]]; then
        xmlstarlet ed -L -P -d "/systemList/system[name='$name']" /etc/emulationstation/es_systems.cfg
    fi
}
