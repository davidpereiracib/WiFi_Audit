# WiFi_Audit – Scripts Automatizados para Auditorías Wi-Fi (Uso Ético)

**WiFi_Audit** es un conjunto de scripts en **Bash** diseñados para facilitar y automatizar tareas comunes durante una auditoría de seguridad Wi-Fi. Estos scripts agilizan procesos como la activación del modo monitor, el reconocimiento de redes, la captura de handshakes y el uso de herramientas como **aircrack-ng** y **wifite**, permitiendo enfocarse en el análisis y la documentación del hallazgo.

---

## ⚠️ Aviso Ético y Legal (Muy Importante)

El uso de estas herramientas **solo está permitido en redes que sean de tu propiedad o sobre las cuales cuentes con una autorización explícita, por escrito, para realizar pruebas de seguridad**.

Cualquier uso indebido puede constituir un delito informático.  
El autor no se hace responsable por daños, mal uso o actividades no autorizadas derivadas del uso de estos scripts.

**Estas herramientas existen únicamente para fines educativos, de investigación y auditorías éticas**.

---

## Características Principales

- Automatización del modo monitor en tarjetas de red compatibles.
- Reconocimiento rápido de redes inalámbricas cercanas.
- Captura facilitada de handshakes WPA/WPA2.
- Interfaces simplificadas para:
  - **aircrack-ng**
  - **wifite**
- Flujo automatizado para auditorías de seguridad Wi-Fi.
- Ideal para entornos como **Kali Linux** u otras distribuciones orientadas a ciberseguridad.

---

## Estructura del Repositorio

```text
WiFi_Audit/
├── auto_aircrack.sh      # Flujo automatizado basado en aircrack-ng
├── auto_wifite.sh        # Ejecución simplificada de wifite
└── full_wifi_audit.sh    # Auditoría Wi-Fi completa (recon + captura + acciones)
