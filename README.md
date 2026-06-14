# Droidspaces-gnome-ubuntu
# note :- To run these steps and properly manage a GNOME session, a solid understanding of Linux and Linux commands is necessary before you can execute them successfully. Please do not ask me any further questions.
<img width="2340" height="1080" alt="1000000060" src="https://github.com/user-attachments/assets/e4e29b61-ad20-48c0-820f-18fd32516e07" />

<img width="1080" height="2340" alt="1000000070" src="https://github.com/user-attachments/assets/ae2a21f3-6b86-4664-8435-b99f2f02415d" />
<img width="1080" height="2340" alt="1000000071" src="https://github.com/user-attachments/assets/2f980aea-7293-4ee0-a886-2afc99c506b9" />


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
z /dev/video* 0660 root render - -
z /dev/media* 0660 root video - -
z /dev/v4l-subdev* 0660 root video - -

# =========================
# KGSL (Qualcomm GPU - standard linux changes to render)
# =========================
z /dev/kgsl-3d0 0660 root render - -

# =========================
# ANDROID BINDER / MEMORY (If using Waydroid/Anbox on Ubuntu)
# =========================
d /dev/binderfs 0775 root root - -
z /dev/binderfs/binder 0666 root render - -
z /dev/binderfs/hwbinder 0666 root render - -
z /dev/binderfs/vndbinder 0666 root render - -

L+ /dev/binder - - - - /dev/binderfs/binder
L+ /dev/hwbinder - - - - /dev/binderfs/hwbinder
L+ /dev/vndbinder - - - - /dev/binderfs/vndbinder

z /dev/ashmem 0666 root render - -
z /dev/ion 0664 root render - -

#d /run/user/1001 0700 debian debian - -
#d /run/user/1000 0700 ubuntu ubuntu - -
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
Exec=env COGL_DRIVER=gles2 GSK_RENDERER=ngl MUTTER_RENDERER=x11 GNOME_SHELL_SESSION_MODE=ubuntu XDG_CURRENT_DESKTOP=ubuntu:GNOME TU_DEBUG=noconform,sysmem ZINK_DESCRIPTORS=lazy MESA_LOADER_DRIVER_OVERRIDE=kgsl VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json MESA_VK_WSI_PRESENT_MODE=mailbox MUTTER_DEBUG_DUMMY_MODE_SPECS=1920x1080@60 DISPLAY=:0 /usr/bin/gnome-shell --x11 --mode=ubuntu
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
export COGL_DRIVER=gles2
export GSK_RENDERER=ngl
export MUTTER_RENDERER=x11

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
