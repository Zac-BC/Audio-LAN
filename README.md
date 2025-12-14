# Audio-LAN

AudioLink es una aplicación móvil diseñada para permitir la transmisión de audio en tiempo real a través de una red local, utilizando dispositivos móviles como fuentes y receptores de sonido. La aplicación se basa en un modelo de roles claramente definido (Maestro y Dependiente), que permite que uno o más dispositivos actúen como micrófonos remotos, mientras que otro actúa como receptor de audio central.

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

# Arquitectura de la aplicación

La aplicación está organizada en una arquitectura clara y modular, separando responsabilidades entre interfaz, lógica y comunicación.

📱 Interfaz de usuario (UI)

- Diseño minimalista, oscuro y moderno, enfocado en la claridad y facilidad de uso.
- Navegación intuitiva mediante pestañas inferiores.
- Botones grandes y claros para acciones críticas (iniciar/detener transmisión).
- Indicadores visuales de audio, conexión y estado del sistema.

🔄 Gestión de estados

- Estados claramente definidos: conectado, transmitiendo, en espera, desconectado.
- Actualización en tiempo real de la interfaz según el estado del audio y la red.
- Preparada para escalar con sistemas de gestión de estado como Provider, Riverpod o Bloc.

📡 Comunicación en red

- Comunicación directa entre dispositivos usando la red local.
- Identificación de dispositivos por nombre y dirección IP.
- Medición de latencia para mostrar el estado de la conexión.
- Envío continuo de paquetes de audio optimizados para baja latencia.

# Pantallas principales
🏠 Pantalla de inicio

- Presenta una introducción clara al propósito de la app.
- Permite seleccionar el rol: Modo Maestro o Modo Dependiente.
- Explica brevemente la función de cada modo para evitar confusión.

🎙️ Pantalla Modo Dependiente

- Botón central grande para iniciar/detener la captura de audio.
- Indicador de conexión con el maestro.
- Medidor de nivel de entrada del micrófono en decibelios.
- Mensajes claros sobre el estado actual (“Listo para transmitir”, “Transmitiendo…”).

🔊 Pantalla Modo Maestro

- Visualización del estado de la red Wi-Fi.
- Indicador visual del audio recibido.
- Lista de dispositivos conectados con:
- - Nombre del dispositivo
- - Dirección IP
- - Latencia estimada
- - Estado de conexión
- Controles para habilitar o deshabilitar la recepción de audio por dispositivo.