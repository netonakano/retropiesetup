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
#   wget https://raw.githubusercontent.com/GeorgeMcMullen/RetroPie-Setup/master/scriptmodules/emulators/mame0200-rPi.sh
#   cd
#   sudo ~/RetroPie-Setup/retropie_setup.sh
# 
# In the RetroPie setup program do the following:
# 
#   Select "P" to Manage packages
#   Select "e" to Manage experimental packages
#   Select "mame0200-rPi"
#   Select "B" to Install from binary
# 
# Then exit the RetroPie setup program.
# Finally, either restart Emulation Station or reboot the machine.
# 
# Place the ROMs in the following directory:
# 
#   /home/pi/RetroPie/roms/mame-mame0200-rPi
#
# On a Raspberry Pi 3 the games can still run rather slowly. When launching,
# hit any button to get into the emulator configuration menu and do the following:
# 
#   Hit "4" to Select video mode for mame0200-rPi
#   Select CEA-1 (640x480 @ 60Hz 4:3, clock:25MHz progressive
#
# TODO: This script does not do any configuration of the existing theme. MAME will show up as its own entry but without any graphics.
#

rp_module_id="mame0200-rPi"
rp_module_desc="MAME v0.200-rPi"
rp_module_help="ROM Extension: .zip\n\nCopy your MAME v0.200-rPi roms to either $romdir/mame-mame0200-rPi or\n$romdir/arcade"
rp_module_licence="GPL2 https://raw.githubusercontent.com/mamedev/mame/master/LICENSE.md"
rp_module_section="exp"
rp_module_flags="!x11 !mali"

debug=0

function depends_mame0200-rPi() {
    getDepends libsdl2-ttf-2.0-0
}

function install_bin_mame0200-rPi() {
    local mame="mame0200-rPi"

    if [[ "$debug" -eq "1" ]]; then
        unzip -n "/home/pi/Downloads/$mame.zip" -d "$md_inst"
    else
        # Download and unzip the binary file 
        # TODO: Test downloadAndExtract
        # downloadAndExtract "https://github.com/GeorgeMcMullen/mame/releases/download/mame0200/mame0200-rPi.zip" "$md_inst"
    
        # TODO: Check for error and exit
        # fatalError "Unable to download and extract."
    
        # Old download and extract code
        wget "https://github.com/GeorgeMcMullen/mame/releases/download/mame0200/mame0200-rPi.zip" -O "$md_inst/$mame.zip"
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

function remove_mame0200-rPi() {
    # Optionally you can remove configureation directories here
    local system="mame-mame0200-rPi"
    rmDirExists "$md_inst"
    rmDirExists "$md_conf_root/$system/"
    rm /home/pi/.mame
    delEmulator "$md_id" "arcade"
    delEmulator "$md_id" "$system"
}

function configure_mame0200-rPi() {
    local system="mame-mame0200-rPi"
    mkRomDir "arcade"
    mkRomDir "$system"
    mkRomDir "$system/artwork"
    mkRomDir "$system/samples"

    if [[ "$md_mode" == "install" ]]; then
        #mkdir -p "$md_conf_root/$system/"{hi,memcard}
        mkdir -p "$md_conf_root/$system/"{cfg,nvram,inp,sta,snap,diff,comments}
        
        if [[ ! -f "/home/pi/.mame" ]]; then
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
