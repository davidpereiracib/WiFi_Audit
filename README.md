# ⚠️ Aviso Ético y Legal (MUY IMPORTANTE)

## El uso de estas herramientas solo está permitido en:

✔ Redes propias
✔ Redes de laboratorio
✔ Redes donde exista autorización explícita por escrito para realizar pruebas de seguridad

Cualquier uso sobre redes de terceros sin autorización constituye un delito informático.
El autor no se hace responsable del uso inadecuado del software.

Estas herramientas existen únicamente para fines éticos, educativos y de auditoría profesional.

# 🛡️ WiFi Audit Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Kali%20Linux-blue.svg)](https://www.kali.org/)
[![Version](https://img.shields.io/badge/Version-1.0-brightgreen.svg)](https://github.com/davidpereiracib/WiFi_Audit/releases)
[![Maintenance](https://img.shields.io/badge/Maintained-Yes-green.svg)](https://github.com/davidpereiracib/WiFi_Audit/graphs/commit-activity)

Herramienta automatizada de auditoría WiFi diseñada para profesionales de seguridad y pruebas de penetración. Automatiza la detección de redes inalámbricas, captura de handshakes WPA/WPA2 y generación de reportes HTML detallados.

## ✨ Características Principales

### Automatización del modo monitor

### Reconocimiento rápido de redes Wi-Fi

### Captura de handshakes WPA/WPA2

### Flujo completo de auditoría

### Wrappers simplificados para:
- aircrack-ng
- wifite

Compatible con Kali Linux y distribuciones similares
---

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Requisitos](#-requisitos)
- [Instalación del Repositorio](#-instalación-del-repositorio)
- [Uso de los Scripts](#-uso-de-los-scripts)
- [Buenas Prácticas de Auditoría Ética](#-buenas-practicas-de-auditoria-etica)
- [Posibles Mejoras Futuras](#-posibles-mejoras-futuras)
- [Autor](#-autor)

---

## ✨ Características

### 🔍 Análisis de Redes
- Escaneo automático de redes WiFi en todos los canales (2.4GHz y 5GHz)
- Detección de dispositivos conectados (clientes)
- Identificación de tipos de cifrado (WEP, WPA, WPA2, WPA3)
- Cálculo de estadísticas de señal y calidad

### 🎯 Captura de Handshakes
- Captura automática de handshakes WPA/WPA2
- Deauthentication attacks dirigidos
- Verificación de handshakes válidos con `aircrack-ng`
- Priorización de redes con mayor señal

### 📊 Reportes Profesionales
- Generación automática de reportes HTML con gráficos interactivos
- Dashboard con estadísticas en tiempo real
- Exportación de datos en formato CSV
- Visualización de distribución de canales, cifrados y fabricantes

### 🔧 Automatización
- Modo monitor automático
- Gestión inteligente de procesos
- Limpieza automática de archivos temporales
- Configuración de ejecución al inicio del sistema (opcional)

---

## 📦 Requisitos

### Hardware Recomendado
- **Adaptador WiFi:** Alfa AWUS036ACH (u otro compatible con modo monitor)
- **Sistema:** Raspberry Pi 4 / Kali Linux en cualquier plataforma
- **RAM:** Mínimo 2GB
- **Almacenamiento:** 500MB libres

### Software
- **SO:** Kali Linux 2023.1 o superior
- **Herramientas:**
  - `aircrack-ng` (>= 1.6)
  - `airmon-ng`
  - `airodump-ng`
  - `aireplay-ng`
  - `wireless-tools`
  - `net-tools`

---

## 🔧 Istalación del Repositorio

```
git clone https://github.com/davidpereiracib/WiFi_Audit.git
cd WiFi_Audit
chmod +x auto_aircrack.sh auto_wifite.sh full_wifi_audit.sh
```

### Instalación de Dependencias (si es necesario)
```
sudo apt update
 sudo apt install -y aircrack-ng wireless-tools net-tools
```
## 🚀 Uso de los Scripts

### ⚠️ RECUERDA:
### No ejecutes estos scripts sobre redes ajenas ni fuera del alcance legal del ejercicio.

### Auditoría Wi-Fi Completa

#### Ejecuta el flujo completo:
```
sudo ./full_wifi_audit.sh
```

Este script realiza:
- Detección o selección de la interfaz Wi-Fi
- Activación del modo monitor
- Escaneo de redes
- Selección de objetivo
- Captura de handshakes
- Almacenamiento de evidencias y resultados

#### Flujo basado en aircrack-ng
```
sudo ./auto_aircrack.sh
```

Acciones típicas:

- Activar modo monitor.
- Escaneo con airodump-ng.
- Opcional: fuerza de handshakes mediante desautenticaciones.
- Exportación de capturas para análisis offline.

#### Flujo basado en wifite
```
sudo ./auto_wifite.sh
```
Acciones típicas:

- Configuración automática de la interfaz.
- Ejecución de wifite con parámetros predefinidos.
- Almacenamiento de capturas y logs.

Salida y Resultados

Los scripts pueden generar:

- Archivos .cap o .pcap con handshakes.
- Listados de redes y clientes cercanos.
- Logs de auditoría con fecha y hora.
- Capturas para uso posterior con aircrack-ng, hashcat o Wireshark.

Puedes ajustar las rutas de salida según tus necesidades.

### Buenas Prácticas de Auditoría Ética

- Solicita siempre autorización explícita antes de auditar una red.
- Usa un entorno de laboratorio controlado cuando estés aprendiendo.
- Documenta cada paso y conserva evidencia para informes formales.
- Complementa estas herramientas con análisis manual en:
  - Wireshark
  - aircrack-ng
  - hashcat

Mantén una correcta segregación entre entornos de prueba y producción.

### Posibles Mejoras Futuras

- Menú interactivo (TUI) para simplificar aún más la ejecución.
- Argumentos CLI (-i, --output, --no-deauth, etc.).
- Mejor manejo de logs y reportes finales automatizados.
- Plantillas de laboratorio para entrenamiento.

## Autor

Desarrollado por David Pereira
GitHub: https://github.com/davidpereiracib

Si deseas contribuir, reportar un bug o proponer mejoras, puedes abrir un issue o enviar un pull request.

