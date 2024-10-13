**Overview**
This solution for MacOS allows to install *Lima VM* with *Ubuntu Server 24.04(x86_64)* and *Xfce* desktop.
Also it downloads *Quartus Prime Lite 20.1.1* and installs it together with *ModelSim*. In addition `qenv.sh` and `quartus/linux64/libedt_wedtq.so` are patched to fix issues with start and -novopt option in Simulator.
By default `quartus` VM is created with an ability to access GUI via *Screen Sharing* utility.
**IMPORTANT** `QuartusVM` folder will be created in your Mac home folder and mounted to the folder `QuartusVM` inside VM. Use this directory to backup any important files from Quartus projects.


**Requirements**
1. 35GB of free disk space.
2. `lima` will be installed by the script but on some laptops it fails to run properly due to firewall or other restrictions.
3. If you have either `admin` or `shadow` username on Mac then you will face some issues with starting LimaVM due to conflicts with standard linux groups. For that case you should either create another user or apply some workarounds.

**Installation**
1. Give exec permissions to `macos_helper_quartus.sh`
`chmod +x macos_helper_quartus.sh`
2. Run the script and wait for completion:
`./macos_helper_quartus.sh`

**How to use?**
0. In terminal run command `limactl start quartus`.
1. Open Screen Sharing(via Cmd + Space or Dock or Applications) and use **vnc://127.0.0.1:5900** as the address of target machine.
2. You will be prompted to enter password. Get it with `cat ~/.lima/quartus/vncpassword`
**NOTE** VNC Password will be changed after each VM reboot.
3. Window with login should be open. By default Username is `user` and Password is `user`; you can change password with `passwd` command inside VM if needed.
4. On Desktop find *Quartus Prime Lite* icon and double click on it to start the software.
**NOTE** During the very first run choose *Mark Executable* and in the next window choose the second option *Run the Quartus Prime software* and then close the program and start it again (Sometimes project creation on first run hang therefore we need that rerun of the program.)
**NOTE** In case of Quartus hang use desktop shortcut *Kill Quartus*.
5. To shutdown VM you can click top right corner with username `user` and use *Shut Down...* option.
If VM doesn't respond you can use `limactl stop quartus` in MacOS terminal or in rare cases forced stop `limactl stop -f quartus` if stopping takes too much time.

**Other**
1. We are using Xfce desktop and GUI. Opened apps are shown at the top of the screen. There is a dock at the bottom with terminal, browser and open folder applications.
2. Ensure that current language on Mac is English while you work inside VM. Ukrainian layout is not supported by default and requires installation of extra packages and additional system configuration.
3. To change display resolution use right click of button on Desktop and then Applications => Settings => Display
