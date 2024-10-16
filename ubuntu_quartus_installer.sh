#!/bin/bash

QUARTUS_LINK="https://cdrdv2.intel.com/v1/dl/getContent/660904/660963?filename=Quartus-lite-20.1.1.720-linux.tar"
QUARTUS_LINK_ACCEPT="https://cdrdv2.intel.com/v1/dl/acceptEula/660904/660963?filename=Quartus-lite-20.1.1.720-linux.tar"
QUARTUS_ARCHIVE="$(realpath ~)/quartus_20.1.1.tar"
QUARTUS_ARCHIVE_HASH="0bebcaece9d8a03af9a69a48adc45634"
INSTALL_DIR="$(realpath ~)/intelFPGA_lite/20.1"
QUARTUS_TMP_DIR=~/quartus

if [ "$#" -eq 1 ]; then
    if [ -f "$1" ]; then
        mv "$1" "${QUARTUS_ARCHIVE}"
    fi
fi

# Download installer archive:
echo "Downloading Quartus Lite installer..."
for i in {1..5}; do
    if [ -f "$QUARTUS_ARCHIVE" ]; then
        if [ $(md5sum "$QUARTUS_ARCHIVE" | awk '{print $1}') = "${QUARTUS_ARCHIVE_HASH}" ]; then
            STATUS="ok"
            break
        fi
    fi

    rm -rf "$QUARTUS_ARCHIVE"
    STATUS="fail"
    wget "${QUARTUS_LINK}" -O "$QUARTUS_ARCHIVE"
    if [ "$?" -ne 0 ]; then
        continue
    elif [ $(md5sum "$QUARTUS_ARCHIVE" | awk '{print $1}') = "${QUARTUS_ARCHIVE_HASH}" ]; then
        STATUS="ok"
        break
    else
        wget "$QUARTUS_LINK_ACCEPT" -O "$QUARTUS_ARCHIVE"
        echo "accept link!!!"
        if [ $(md5sum "$QUARTUS_ARCHIVE" | awk '{print $1}') = "${QUARTUS_ARCHIVE_HASH}" ]; then
            STATUS="ok"
            break
        fi
    fi

    echo -e "ERROR: Failed to download $QUARTUS_ARCHIVE, retrying..."
    sleep 5
done

if [ "$STATUS" = "fail" ]; then
    echo "ERROR: Failed to download quartus installer"
    exit 1
fi

# Extract archive to the folder and remove archive file to save some space:
echo "Extracting Quartus Lite installer..."
mkdir "$QUARTUS_TMP_DIR"
tar xvf "$QUARTUS_ARCHIVE" -C "$QUARTUS_TMP_DIR"
rm "$QUARTUS_ARCHIVE"

# We need to remove unneeded boards and installers to save some space:
echo "Removing unneeded components from installer..."
cd "${QUARTUS_TMP_DIR}/components"
rm -rf QuartusHelpSetup-20.1.1.720-linux.run arria_*.qdz max*.qdz cyclonev*.qdz cyclone10*.qdz

# Install Quartus Lite and board config:
echo "Installing Quartus Lite..."
./QuartusLiteSetup-20.1.1.720-linux.run --mode unattended --unattendedmodeui minimal --accept_eula 1 --installdir $INSTALL_DIR
rm ./QuartusLiteSetup-20.1.1.720-linux.run

# Install Model Simulator:
echo "Installing Model Simulator..."
./ModelSimSetup-20.1.1.720-linux.run --mode unattended --unattendedmodeui minimal --accept_eula 1 --installdir $INSTALL_DIR

# Remove temporary directory:
rm -rf "${QUARTUS_TMP_DIR}"

# Patch Quartus startup environment script for aarch64 Ubuntu:
if [ "$(uname -m)" = "aarch64" ]; then
    QENV_FILE="$INSTALL_DIR/quartus/adm/qenv.sh"
    sed -i 's/x86_64/aarch64/g' "$QENV_FILE"
    sed -i 's/"$cpumodel"/"Nehalem"/g' "$QENV_FILE"
    sed -i 's/grep sse/grep fp/g' "$QENV_FILE"
fi

# There is an issue with extra option -novopt in Model Simulator - it was added by default but it blocks simulation start.
# We can just patch corresponding library with substitution of that symbols with the same amount of spaces.
# Spaces are required to ensure that all the relative addresses will be the same after replace.
FILE=${INSTALL_DIR}/quartus/linux64/libedt_wedtq.so
if [ ! -f "${FILE}orig" ]; then cp "${FILE}" "${FILE}orig"; sed -i 's/-novopt /        /g' "${FILE}"; fi

# Add shortcut to Desktop to run Quartus:
mkdir -p ~/Desktop
echo '#!'"""/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=./quartus
Path=${INSTALL_DIR}/quartus/bin/
Icon=${INSTALL_DIR}/quartus/common/tcl/packages/dse/pjm.gif
Name=Quartus Prime Lite
Comment=Launch Quartus Prime Lite
""" > ~/Desktop/Quartus.desktop
chmod +x ~/Desktop/Quartus.desktop

# Add shortcut to kill Quartus in case of hang:
echo -e '#!'"/bin/bash\n\nkill -9 \$(ps aux | grep quartus\$ | awk '{print $2}')\n" > "${INSTALL_DIR}/quartus/kill_quartus.sh"
chmod +x "${INSTALL_DIR}/quartus/kill_quartus.sh"

echo '#!'"""/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Exec="${INSTALL_DIR}/quartus/kill_quartus.sh"
Icon=${INSTALL_DIR}/quartus/kill_quartus.sh
Name=Kill Quartus
Comment=Kill Quartus Prime Lite
""" > ~/Desktop/KillQuartus.desktop
chmod +x ~/Desktop/KillQuartus.desktop


# Just report installation success:
echo "Quartus Prime Lite and Model Simulator was installed successfully."
