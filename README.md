# Overview

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation and Usage](#installation-and-usage)
  - [How to Use (VZ Installation)](#how-to-use-vz-installation)
  - [How to Use (QEMU Installation)](#how-to-use-qemu-installation)
  - [Other](#other)
- [Flashing with OpenOCD](#flashing-with-openocd)
  - [SVF Generation](#svf-generation)
  - [macOS](#macos)
  - [Windows on AMD CPU](#windows-on-amd-cpu)
  - [Notes](#notes)

This solution for macOS enables the installation of *Lima VM* with *Ubuntu Server 24.04* and *Xfce* desktop to support running Quartus Prime software on a macOS host system.

It also includes instructions for board flashing with OpenOCD on macOS and Windows machines with AMD CPUs. The macOS solution can be adapted for Linux if needed.

Key features:

- The `quartus` VM supports GUI access:
  - For **vz**, a GUI window opens automatically.
  - For **qemu**, use the *Screen Sharing* utility.

- USB-Blaster support is enabled with VirtualHere Client installed in the VM. Install and run VirtualHere Server on your Mac (https://www.virtualhere.com/osx_server_software). This works for Intel-based Macs; for M-series CPUs, follow the instructions in the **Flashing with OpenOCD** section.

- A *USB Client* desktop shortcut runs the client and restarts jtagd. On first use, select *Auto-Use Device* for USB-Blaster in the VirtualHere Client to enable automatic reconnection.

- `x86_64` Ubuntu is used for Intel-based Macs.

- `aarch64` Ubuntu is used for Apple M-series processors.

- `qemu-user-static` with amd64 and i386 packages ensures Quartus compatibility.

- The script automatically downloads and installs *Quartus Prime Lite 20.1.1* with *ModelSim*.

- `qenv.sh` is patched to resolve startup issues on aarch64 machines.

- `quartus/linux64/libedt_wedtq.so` is patched to fix a `-novopt` error in the Simulator.

**Important:** The `QuartusVM` folder is created in your Mac home directory and mounted to `/home/user/QuartusVM` inside the VM. Use this directory for Quartus projects and backups. Files are stored on your Mac and persist even if the VM fails.

- The repository includes a PowerShell script to install a Multipass Ubuntu VM for board flashing on Windows laptops with AMD CPUs, addressing USB-Blaster driver issues.

## Requirements

1. 35 GB of free disk space.
2. The script installs `lima`, but it may fail on some laptops due to firewall or other restrictions.
3. Using `admin` or `shadow` as a macOS username may cause conflicts with standard Linux groups. Create a new user or apply workarounds.

## Installation and Usage

1. Grant execute permissions to `macos_helper_quartus.sh`:
   ```bash
   chmod +x macos_helper_quartus.sh
   ```

2. Run the script and wait for completion:
   ```bash
   ./macos_helper_quartus.sh vz
   ```

   **Note:** Prefer `vz` (Apple Virtualization Framework). If issues persist after several attempts, reinstall with `qemu`:
   ```bash
   ./macos_helper_quartus.sh qemu
   ```
   Follow the *How to Use (QEMU Installation)* instructions for proper VM operation.

3. If Quartus download fails, use the *Install Quartus* desktop shortcut inside VM and follow its instructions.

### How to Use (VZ Installation)

1. Run `limactl start quartus` in the terminal.

2. A login window should appear. Default credentials are Username: `user`, Password: `user`. Change the password with shell command `passwd` inside the VM if needed.

3. Double-click the *Quartus Prime Lite* desktop icon to start the software.

   **Note:** On the first run, select *Mark Executable*, then choose *Run the Quartus Prime software* in the next window.

   **Note:** If Quartus hangs, use the *Kill Quartus* desktop shortcut.

4. To flash a board, run VirtualHere Server on macOS, then use the *USB Client* shortcut on the VM desktop. If the Quartus Tools => Programmer window is open, close and reopen it, as Quartus does not detect the programmer automatically.

   **Important:** This may not work reliably on ARM-based Macs. Use `openocd` instead (check the **Flashing with OpenOCD** section).

5. To shut down the VM, click the top-right corner (username `user`) and select *Shut Down...*. If the VM is unresponsive, use `limactl stop quartus` in the macOS terminal, or `limactl stop -f quartus` for a forced stop if it takes too long.

### How to Use (QEMU Installation)

1. Run `limactl start quartus` in the terminal.

2. Open *Screen Sharing* (via Cmd + Space, Dock, or Applications) and enter `vnc://127.0.0.1:5900` as the target address.

3. Enter the VNC password, obtained with:
   ```bash
   cat ~/.lima/quartus/vncpassword
   ```

   **Note:** The VNC password changes after each VM reboot.

4. A login window should appear. Default credentials are Username: `user`, Password: `user`. Change the password with `passwd` inside the VM if needed.

5. Double-click the *Quartus Prime Lite* desktop icon to start the software.

   **Note:** On the first run, select *Mark Executable*, choose *Run the Quartus Prime software*, close the program, and restart it. (Initial project creation may hang, requiring a rerun.)

   **Note:** If Quartus hangs, use the *Kill Quartus* desktop shortcut.

6. To flash a board, run VirtualHere Server on macOS, then use the *USB Client* shortcut on the VM desktop. If the Quartus Tools => Programmer window is open, close and reopen it, as Quartus does not detect the programmer automatically.

   **Important:** This may not work reliably on ARM-based Macs. Use `openocd` instead (check the **Flashing with OpenOCD** section).

7. To shut down the VM, click the top-right corner (username `user`) and select *Shut Down...*. If the VM is unresponsive, use `limactl stop quartus` in the macOS terminal, or `limactl stop -f quartus` for a forced stop if it takes too long.

### Other

1. The Xfce desktop and GUI are used. Open apps appear at the top of the screen, with a dock at the bottom containing terminal, browser, and file explorer applications.
2. Ensure the macOS language is set to English while working in the VM. Ukrainian layout is not supported by default and requires additional package installation and system configuration.
3. To change the display resolution, right-click the desktop, then select Applications => Settings => Display.

## Flashing with OpenOCD

This guide provides an alternative method to flash the ALTERA CYCLONE IV EP4CE6 board using OpenOCD. It can be adapted for other boards by editing `board.cfg` according to the target board's specifications. This approach is useful for macOS and Windows with AMD CPUs.

### SVF Generation

For both platforms, first export the project to SVF format:

1. **Compile your design** in Intel Quartus Prime to generate a `.sof` or `.pof` file.
2. **Open the Programmer** via Tools > Programmer from the main menu. Ensure the `.sof` or `.pof` file appears in the Programmer window; if not, add it.
3. **Create the SVF file** by navigating to File > Create JAM, JBC, SVF, or ISC File... in the Programmer window.
4. **Select SVF format**: In the dialog box, choose "Serial Vector File (SVF)" from the File Format dropdown and specify the output file name.
5. **Click OK** to generate the SVF file.

## MacOS

1. Install OpenOCD with:
   ```bash
   brew install openocd
   ```
2. Use your Quartus virtual machine to generate the SVF file, following the **SVF Generation** section.
3. Locate the generated SVF file and ensure macOS can access it, e.g., by placing it in the shared folder `/home/user/QuartusVM`.
4. In the macOS Terminal, run:
   ```bash
   MY_SVF_FILE=path/to/svf/file/project.svf openocd -f path/to/board.cfg
   ```
   where `project.svf` is your generated SVF file and `board.cfg` is the file from this repository.
5. The board's program should update. Note: The program resets to default upon board reboot.

### Windows on AMD CPU

**Note:** In Device Manager, ensure the USB-Blaster is recognized as `Altera USB-Blaster`. If it appears as an unknown device, connect it via a USB hub or adapter instead of directly to the laptop.

1. **Install `usbipd` and bind USB-Blaster** (run in PowerShell with Administrator permissions). Required for first-time setup or if the USB-Blaster is plugged into a new USB port:
   ```powershell
   winget install --id dorssel.usbipd-win -e
   usbipd bind -b $(usbipd.exe list | findstr "Altera USB-Blaster" | ForEach-Object { $_ -split '\s+' | Select-Object -First 1 })
   ```

   **Subsequent steps can be performed in a regular PowerShell without Administrator permissions.**

2. **Create and set up VM**: Ensure `multipass` is installed. Enable script execution for the current session (type `Y` and Enter) and run the Quartus VM installation:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted
   .\install_quartus_vm.ps1
   ```

3. **Attach device to VM**: On VM restart or USB-Blaster reconnection, run:
   ```powershell
   multipass exec quartus-vm -- bash -c 'HOST_IP=$(ip route | grep default | cut -f3 -d\ ); sudo apt install -y linux-modules-extra-$(uname -r) && sudo modprobe vhci-hcd && sudo usbip attach -r $HOST_IP -b $(usbip list --remote=$HOST_IP | grep "Blaster" | cut -f 1 -d:) && sleep 1 && lsusb'
   ```

4. **Prepare SVF file**: Follow the **SVF Generation** section above.

5. **Flash the board**: Place `board.cfg` from this repository and the generated SVF file (`project.svf`, name may vary) in the shared folder `~/quartus-shared` (in your home directory), then run:
   ```powershell
   multipass exec quartus-vm -- bash -c "cd ~/quartus-shared; MY_SVF_FILE=project.svf openocd -f board.cfg"
   ```

6. **Stop VM**: When done, run:
   ```powershell
   multipass stop quartus-vm
   ```

### Notes

- If you plug/unplug the device, rerun step 1 (if the USB port changed) and step 3.
- After a VM restart, run step 3 first.
- To remove the VM, use:
   ```powershell
   multipass delete --purge quartus-vm
   ```
