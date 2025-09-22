multipass launch 24.04 --name=quartus-vm
multipass set local.privileged-mounts=true
New-Item -Path "$env:USERPROFILE\quartus-shared" -ItemType Directory -Force
$command = "multipass mount '$env:USERPROFILE\quartus-shared' quartus-vm:/home/ubuntu/quartus-shared"
1..3 | ForEach-Object {
    try {
        Invoke-Expression $command -ErrorAction Stop
        return
    } catch {
        Write-Host "Attempt $_ failed: $_"
        if ($_ -lt 3) { Start-Sleep 2 } else { Write-Host "Failed after 3 attempts"; exit 1 }
    }
}
multipass exec quartus-vm -- bash -c 'sudo apt update && sudo apt upgrade -y && sudo apt install -y openocd libftdi1 libftdi1-dev linux-tools-common hwdata linux-tools-generic linux-generic linux-modules-extra-$(uname -r) && sudo modprobe vhci-hcd' 
$command = @"
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6001", MODE="0666", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/99-usbblaster.rules && echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", ATTR{idProduct}=="6010", MODE="0666", GROUP="plugdev"' | sudo tee -a /etc/udev/rules.d/99-usbblaster.rules
"@
multipass exec quartus-vm -- bash -c $command
multipass exec quartus-vm -- bash -c 'sudo usermod -a -G plugdev $USER'
multipass stop quartus-vm
