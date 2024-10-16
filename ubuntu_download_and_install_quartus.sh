#!/bin/bash

echo "Browser will be opened to start the download. Accept license if needed."
echo "Script will automatically detect download completion"
echo "        and will proceed with Quartus installation."
echo "Press Enter to start"
read $VAR

QUARTUS_LINK="https://cdrdv2.intel.com/v1/dl/getContent/660904/660963?filename=Quartus-lite-20.1.1.720-linux.tar"
DOWNLOAD_FILE="$(realpath ~)/Downloads/Quartus-lite-20.1.1.720-linux.tar"
chromium-browser ${QUARTUS_LINK} &

WAIT_MSG="Waiting for download completion"
while [ true ]; do
    if [ -f "${DOWNLOAD_FILE}" ]; then
        break
    fi
    for((i=0;i<5;i++))
    do
        echo -n -e "${WAIT_MSG}.  \r"
        sleep 1
        echo -n -e "${WAIT_MSG}.. \r"
        sleep 1
        echo -n -e "${WAIT_MSG}...\r"
        sleep 1
    done
done

echo "File was downloaded. Trying to install Quartus."
chmod +x ~/ubuntu_quartus_installer.sh
~/ubuntu_quartus_installer.sh "${DOWNLOAD_FILE}"
