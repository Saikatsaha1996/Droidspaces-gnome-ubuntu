# Droidspaces-gnome-ubuntu
# note :- To run these steps and properly manage a GNOME session, a solid understanding of Linux and Linux commands is necessary before you can execute them successfully. Please do not ask me any further questions.
<img width="2340" height="1080" alt="1000000060" src="https://github.com/user-attachments/assets/e4e29b61-ad20-48c0-820f-18fd32516e07" />

Gnome session with termux x11 compositor

1st install ubuntu minimal rootfs & create tmpfiles config

# note :- all config not same for all devices also you can skip this step
```
nano /etc/tmpfiles.d/android-devices.conf
```
```
# =========================
# DRI / GPU
# =========================
d /dev/dri 0755 root root - -
z /dev/dri/card* 0660 root video - -
z /dev/dri/renderD* 0660 root render - -

# =========================
# INPUT
# =========================
d /dev/input 0755 root root - -
z /dev/input/event* 0660 root input - -
z /dev/input/mouse* 0660 root input - -
z /dev/input/mice 0660 root input - -

# =========================
# SOUND
# =========================
d /dev/snd 0755 root root - -
z /dev/snd/* 0660 root audio - -

# =========================
# VIDEO / MEDIA (V4L)
# =========================
z /dev/video* 0660 root video - -
z /dev/media* 0660 root video - -
z /dev/v4l-subdev* 0660 root video - -

# =========================
# KGSL (Qualcomm GPU - standard linux changes to render)
# =========================
z /dev/kgsl-3d0 0660 root render - -

# =========================
# ANDROID BINDER / MEMORY (If using Waydroid/Anbox on Ubuntu)
# =========================
z /dev/binder 0666 root render - -
z /dev/hwbinder 0666 root render - -
z /dev/vndbinder 0666 root render - -
z /dev/ashmem 0666 root root - -
z /dev/ion 0664 root render - -
```
```
systemd-tmpfiles --create /etc/tmpfiles.d/android-devices.conf
```
2nd install minimal packages
```
sudo apt install ubuntu-desktop-minimal sudo nano
```
3rd user creation & permission for user
```
sudo adduser ubuntu
```
permission
```
sudo usermod -aG sudo,video,audio,input,render,plugdev,adm ubuntu
```
edit
```
sudo nano /usr/share/applications/org.gnome.Shell.desktop
```
replace
```
Exec=/usr/bin/gnome-shell
```
to
```
Exec=/usr/bin/gnome-shell --nested --mode=ubuntu -d :0 --wayland-display=wayland-0
```
run
```
sudo update-desktop-database /usr/share/applications/
```
set environment variables to .bashrc, profile 
# note :- display resolution, display refresh rate , gpu driver not same for all devices
```
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export TU_DEBUG=noconform,sysmem
export ZINK_DESCRIPTORS=lazy
export MESA_LOADER_DRIVER_OVERRIDE=kgsl
export GSK_RENDERER=ngl
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
export MESA_VK_WSI_PRESENT_MODE=mailbox
export MUTTER_DEBUG_DUMMY_MODE_SPECS=1920x1080@60
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0
```
reboot & open user terminal and minimise
run termux x11 with
```
termux-x11 -ac -force-sysvshm :0 &
```
now run
```
dbus-run-session -- gnome-session
```
