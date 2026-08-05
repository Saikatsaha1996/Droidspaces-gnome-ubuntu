#!/usr/bin/env bash
set -e

# =====================================================================
# [PRoot LOCALE & ENCODING FIX] Bypasses terminal exit status 8 crashes
# =====================================================================
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

# Generate locale if missing inside the PRoot architecture
if ! locale -a | grep -q "en_US.utf8"; then
    echo "Fixing missing system UTF-8 encoding patterns..."
    sudo apt-get update && sudo apt-get install -y locales
    sudo locale-gen en_US.UTF-8 || true
    sudo update-locale LANG=en_US.UTF-8 || true
fi

# Ensure Desktop directory exists for DING extension
[ ! -d "$HOME/Desktop" ] && mkdir -p "$HOME/Desktop"

sudo chmod -R 777 /tmp/anland
SOCKET=wayland-anland
ANLAND_SOCKET=/tmp/anland/display_daemon.sock
export XDG_RUNTIME_DIR=/run/user/$(id -u)

sudo mkdir -p "$XDG_RUNTIME_DIR"
sudo chown "$(id -u):$(id -g)" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

rm -f "$XDG_RUNTIME_DIR"/wayland-* > /dev/null 2>&1

sudo mkdir -p /tmp/.X11-unix
sudo chmod 1777 /tmp/.X11-unix

pkill -x weston 2>/dev/null || true
pkill -x gnome-shell 2>/dev/null || true
pkill -x pipewire 2>/dev/null || true
pkill -x wireplumber 2>/dev/null || true
pkill -x pipewire-pulse 2>/dev/null || true
pkill -x dbus-daemon 2>/dev/null || true
pkill -x Xwayland 2>/dev/null || true

sleep 1

rm -f \
    "$XDG_RUNTIME_DIR/$SOCKET" \
    "$XDG_RUNTIME_DIR/$SOCKET.lock"
rm -f /tmp/.X11-unix/X*

unset DISPLAY

export WAYLAND_DISPLAY=$SOCKET
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
export TU_DEBUG=noconform
export EGL_PLATFORM=surfaceless
export MESA_LOADER_DRIVER_OVERRIDE=kgsl
export TURNIP_KMD=kgsl
export GALLIUM_DRIVER=freedreno
export FD_FORCE_KGSL=1
export XWAYLAND_FORCE_KGSL_SURFACELESS=1
export ANLAND_NO_DRM_DEVICE=1

sleep 1

# =====================================================================
# [BYPASS logind & CRITICAL DBUS LOCK] Fake system bus endpoints
# =====================================================================
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ] || [ ! -S "${DBUS_SESSION_BUS_ADDRESS#*=}" ]; then
    echo "Starting a local custom D-Bus session..."
    DBUS_OUTPUT=$(dbus-daemon --session --print-address --fork)
    export DBUS_SESSION_BUS_ADDRESS="$DBUS_OUTPUT"
fi

if [ -z "$DBUS_SYSTEM_BUS_ADDRESS" ]; then
    echo "Faking a System Bus endpoint..."
    export DBUS_SYSTEM_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS"
fi

export GNOME_CONTROL_CENTER_DESKTOP=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export XDG_SESSION_DESKTOP=ubuntu
export G_DBUS_COOKIE_SHA1_KEYRING_DIR="$XDG_RUNTIME_DIR/.gdbus-keyring"
mkdir -p "$G_DBUS_COOKIE_SHA1_KEYRING_DIR" && chmod 700 "$G_DBUS_COOKIE_SHA1_KEYRING_DIR"
export G_DBUS_SYSTEM_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS"

# Mock login1 and Accounts services natively on the fake system bus
dbus-send --system --type=method_call --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.RequestName string:"org.freedesktop.login1" uint32:4 || true
dbus-send --system --type=method_call --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.RequestName string:"org.freedesktop.Accounts" uint32:4 || true
export SYSTEMD_PROC_CMDLINE="init"

export PIPEWIRE_RUNTIME_DIR="$XDG_RUNTIME_DIR"
export PULSE_RUNTIME_PATH="$XDG_RUNTIME_DIR/pulse"
export PULSE_SERVER="unix:$PULSE_RUNTIME_PATH/native"

mkdir -p "$PULSE_RUNTIME_PATH"

if command -v pipewire >/dev/null 2>&1; then
    pipewire >/dev/null 2>&1 &
fi
sleep 0.5
if command -v wireplumber >/dev/null 2>&1; then
    wireplumber >/dev/null 2>&1 &
fi
sleep 0.5
if command -v pipewire-pulse >/dev/null 2>&1; then
    pipewire-pulse >/dev/null 2>&1 &
fi

sleep 1

# Weston startup running your patched Xwayland server mapping cleanly
weston \
    --backend=anland \
    --renderer=gl \
    --disp-sock=$ANLAND_SOCKET \
    --socket=$SOCKET \
    --scale=2 \
    --xwayland \
    --shell=kiosk-shell.so \
    --no-config &

WESTON_PID=$!

for i in $(seq 1 50); do
    [ -S "$XDG_RUNTIME_DIR/$SOCKET" ] && break
    sleep 0.1
done

sleep 1

# =====================================================================
# [EXPORT GLOBAL VARIABLES]
# =====================================================================
#export DISPLAY=:0
export WAYLAND_DISPLAY=$SOCKET
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export GNOME_SHELL_SESSION_MODE=ubuntu
export GDK_SCALE=2
export GDK_DPI_SCALE=1
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
export TU_DEBUG=noconform
export EGL_PLATFORM=surfaceless
export MESA_LOADER_DRIVER_OVERRIDE=kgsl
export TURNIP_KMD=kgsl
export GALLIUM_DRIVER=freedreno
export FD_FORCE_GSGL=1
export XWAYLAND_FORCE_KGSL_SURFACELESS=1
export ANLAND_NO_DRM_DEVICE=1
export GIO_USE_VFS=local
export NO_GAIL=1
export MUTTER_DEBUG_DISABLE_HW_CURSORS=1
export CLUTTER_ACTOR_PROFILE=0
export GNOME_TERMINAL_DISABLE_FACTORY=1
export MUTTER_XWAYLAND_PATH=/usr/bin/true
export VTE_PCI_DEVICE_PATH=""

# =====================================================================
# [FIX] GNOME Settings Desktop Icon Launcher Patch
# =====================================================================
mkdir -p "$HOME/.local/share/applications"

if [ -f "/usr/share/applications/org.gnome.Settings.desktop" ]; then
    TARGET_DESKTOP="org.gnome.Settings.desktop"
else
    TARGET_DESKTOP="gnome-control-center.desktop"
fi

cp "/usr/share/applications/$TARGET_DESKTOP" "$HOME/.local/share/applications/" || true
sed -i 's/DBusActivatable=true/DBusActivatable=false/g' "$HOME/.local/share/applications/$TARGET_DESKTOP" || true

echo "Launching GNOME Shell..."
exec gnome-shell --mode=ubuntu --devkit

kill $WESTON_PID 2>/dev/null
wait $WESTON_PID 2>/dev/null
