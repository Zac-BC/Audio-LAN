# Audio-LAN
AudioLink is a mobile application designed to enable real-time audio streaming over a local network, using mobile devices as both sound sources and receivers. The application is based on a clearly defined role model—Master and Dependent—which allows one or more devices to act as remote microphones, while another serves as the central audio receiver

El objetivo principal de AudioLink es ofrecer una solución simple, eficiente y de baja latencia para la captura y reproducción de audio sin necesidad de hardware adicional, cables o conexiones a internet, aprovechando únicamente la conectividad local (Wi-Fi).


# Concepto de funcionamiento

AudioLink funciona exclusivamente dentro de una red local (LAN). Todos los dispositivos deben estar conectados al mismo punto de acceso Wi-Fi para poder comunicarse entre sí.

La aplicación permite seleccionar uno de dos roles:

🔹 Modo Maestro

El dispositivo en modo maestro actúa como receptor de audio. Es el encargado de:
- Detectar dispositivos dependientes disponibles en la red local.
- Recibir el audio transmitido desde uno o varios dependientes.
- Reproducir el audio en tiempo real a través de sus altavoces o salida de audio.
- Gestionar las conexiones activas (activar/desactivar dispositivos).
- Mostrar información relevante como latencia, estado de conexión y nivel de actividad.

🔹 Modo Dependiente

El dispositivo en modo dependiente actúa como emisor de audio, utilizando su micrófono integrado para:
- Capturar audio en tiempo real.
- Enviar el flujo de audio al dispositivo maestro a través de la red local.
- Mostrar el nivel de entrada del micrófono.
- Indicar claramente el estado de conexión y transmisión.
- Este enfoque permite escenarios como:
- Uso de varios teléfonos como micrófonos inalámbricos.
- Captura de audio desde distintas ubicaciones de una habitación.
- Ampliación de la captación sonora sin equipamiento profesional.