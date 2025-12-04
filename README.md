# WiFi_Audit – Scripts Automatizados para Auditorías Wi-Fi (Uso Ético)

**WiFi_Audit** es un conjunto de scripts en **Bash** diseñados para facilitar y automatizar tareas comunes durante una auditoría de seguridad Wi-Fi. Estos scripts agilizan procesos como la activación del modo monitor, el reconocimiento de redes, la captura de handshakes y el uso de herramientas como **aircrack-ng** y **wifite**, permitiendo enfocarse en el análisis y la documentación del hallazgo.

---

## ⚠️ Aviso Ético y Legal (SUPER IMPORTANTE!!!)

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

Cada script contiene un flujo claro que puedes revisar y personalizar según tus necesidades de práctica o auditoría.

Requisitos

Linux con:

bash

aircrack-ng

wifite

iw, iproute2 y herramientas estándar de red

Adaptador Wi-Fi con soporte para:

Monitor mode

Packet injection

Privilegios de superusuario (sudo)

Instalación sugerida en Kali Linux:

sudo apt update
sudo apt install aircrack-ng wifite

Instalación
git clone https://github.com/davidpereiracib/WiFi_Audit.git
cd WiFi_Audit
chmod +x auto_aircrack.sh auto_wifite.sh full_wifi_audit.sh

Uso de los Scripts

⚠️ Recuérdalo siempre:
No ejecutes estos scripts en redes de terceros ni fuera del alcance legal del ejercicio.

1. Auditoría Wi-Fi completa

Ejecuta todo el flujo automatizado de reconocimiento y captura:

sudo ./full_wifi_audit.sh


Este script generalmente:

Detecta o solicita la interfaz Wi-Fi.

Activa modo monitor.

Escanea redes disponibles.

Permite seleccionar objetivo.

Captura handshakes u otra información relevante.

Guarda resultados para análisis posterior.

2. Workflow basado en aircrack-ng
sudo ./auto_aircrack.sh


Acciones típicas:

Activar modo monitor.

Escaneo con airodump-ng.

Opcional: fuerza de handshakes mediante desautenticaciones.

Exportación de capturas para análisis offline.

3. Workflow basado en wifite
sudo ./auto_wifite.sh


Acciones típicas:

Configuración automática de la interfaz.

Ejecución de wifite con parámetros predefinidos.

Almacenamiento de capturas y logs.

Salida y Resultados

Los scripts pueden generar:

Archivos .cap o .pcap con handshakes.

Listados de redes y clientes cercanos.

Logs de auditoría con fecha y hora.

Capturas para uso posterior con aircrack-ng, hashcat o Wireshark.

Puedes ajustar las rutas de salida según tus necesidades.

Buenas Prácticas de Auditoría Ética

Solicita siempre autorización explícita antes de auditar una red.

Usa un entorno de laboratorio controlado cuando estés aprendiendo.

Documenta cada paso y conserva evidencia para informes formales.

Complementa estas herramientas con análisis manual en:

Wireshark

aircrack-ng

hashcat

Asegura una correcta segregación entre entornos de prueba y producción.

Posibles Mejoras Futuras

Menú interactivo (TUI) para simplificar aún más la ejecución.

Argumentos CLI (-i, --output, --no-deauth, etc.).

Mejor manejo de logs y reportes finales automatizados.

Plantillas de laboratorio para entrenamiento.

Autor

Desarrollado por David Pereira
GitHub: https://github.com/davidpereiracib

Si deseas contribuir, reportar un bug o proponer mejoras, puedes abrir un issue o enviar un pull request.

🛑 Recuerda

La ciberseguridad ética se basa en el consentimiento, la transparencia y la responsabilidad.
Usa estas herramientas como medio para aprender, enseñar y fortalecer redes, nunca para vulnerarlas sin permiso.


