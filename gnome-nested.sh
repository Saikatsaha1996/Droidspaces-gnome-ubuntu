#!/usr/bin/env bash
set -e

SOCKET=wayland-anland
ANLAND_SOCKET=/tmp/anland/display_daemon.sock

export XDG_RUNTIME_DIR=/run/user/$(id -u)

sudo mkdir -p "$XDG_RUNTIME_DIR"
sudo chown "$(id -u):$(id -g)" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

sudo mkdir -p /tmp/.X11-unix
sudo chmod 1777 /tmp/.X11-unix

sudo chmod 666 "$ANLAND_SOCKET" 2>/dev/null || true

pkill -x weston 2>/dev/null || true
pkill -x gnome-shell 2>/dev/null || true
pkill -x pipewire 2>/dev/null || true
pkill -x wireplumber 2>/dev/null || true
pkill -x pipewire-pulse 2>/dev/null || true

rm -f \
    "$XDG_RUNTIME_DIR/$SOCKET" \
    "$XDG_RUNTIME_DIR/$SOCKET.lock"

unset DISPLAY

export WAYLAND_DISPLAY=$SOCKET
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_DESKTOP=GNOME
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
export TU_DEBUG=noconform
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export MUTTER_DEBUG_DUMMY_MODE_SPECS=1920x1080@60
export MESA_LOADER_DRIVER_OVERRIDE=kgsl
export TURNIP_KMD=kgsl
export GALLIUM_DRIVER=freedreno
export FD_FORCE_KGSL=1
export XWAYLAND_FORCE_KGSL_SURFACELESS=1

export ANLAND_WESTON_XWAYLAND=1

dbus-run-session -- bash <<EOF

export PIPEWIRE_RUNTIME_DIR="$XDG_RUNTIME_DIR"
export PULSE_RUNTIME_PATH="$XDG_RUNTIME_DIR/pulse"
export PULSE_SERVER="unix:\$PULSE_RUNTIME_PATH/native"

mkdir -p "\$PULSE_RUNTIME_PATH"

if command -v pipewire >/dev/null 2>&1; then
    pipewire >/dev/null 2>&1 &
fi

sleep 1

if command -v wireplumber >/dev/null 2>&1; then
    wireplumber >/dev/null 2>&1 &
fi

sleep 1

if command -v pipewire-pulse >/dev/null 2>&1; then
    pipewire-pulse >/dev/null 2>&1 &
fi

sleep 1

weston \
    --backend=anland \
    --renderer=gl \
    --disp-sock=$ANLAND_SOCKET \
    --socket=$SOCKET \
    --xwayland \
    --shell=desktop-shell.so \
    --no-config &

WESTON_PID=\$!

for i in \$(seq 1 50); do
    [ -S "$XDG_RUNTIME_DIR/$SOCKET" ] && break
    sleep 0.1
done

export WAYLAND_DISPLAY=$SOCKET
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_DESKTOP=GNOME
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
export TU_DEBUG=noconform
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export MUTTER_DEBUG_DUMMY_MODE_SPECS=1920x1080@60
export MESA_LOADER_DRIVER_OVERRIDE=kgsl
export TURNIP_KMD=kgsl
export GALLIUM_DRIVER=freedreno
export FD_FORCE_KGSL=1
export XWAYLAND_FORCE_KGSL_SURFACELESS=1

exec gnome-shell --devkit --mode=ubuntu

kill \$WESTON_PID 2>/dev/null
wait \$WESTON_PID 2>/dev/null

EOF
