# Contributing

Este documento contiene las pautas para desarrollar, modificar y mantener **AHK OBS Controller**.

## Arquitectura

El flujo principal del proyecto es:

```text
USB Numpad
    │
    ▼
AutoHotInterception
    │
    ▼
AutoHotkey
    │
    ▼
OBS WebSocket
    │
    ▼
OBS Studio
```

AutoHotInterception permite identificar específicamente el teclado numérico configurado.

AutoHotkey procesa las teclas y ejecuta las acciones correspondientes.

La comunicación con OBS se realiza mediante OBS WebSocket.

## Entorno de desarrollo

Para desarrollar el proyecto se necesita:

* Windows
* AutoHotkey v2
* OBS Studio
* OBS WebSocket 5.x
* Interception Driver
* Teclado numérico compatible

## Estructura del código

### `numpad_obs.ahk`

Es el controlador principal.

Contiene:

* Lectura de configuración.
* Conexión con OBS.
* Interfaz gráfica.
* Identificación del teclado.
* Asociación de teclas con acciones.
* Cambio de escenas.
* Control de volumen.
* Lógica de fades.

### `Monitor.ahk`

Contiene funcionalidades relacionadas con el monitoreo del sistema/proyecto.

### `config.ini`

Contiene parámetros configurables que no son secretos.

No se deben almacenar contraseñas ni otras credenciales en este archivo.

### `password.ini`

Contiene las credenciales locales de OBS.

Este archivo está excluido del repositorio mediante `.gitignore`.

### `Lib/`

Contiene las dependencias utilizadas por el proyecto.

Las librerías de terceros deben mantenerse sin modificaciones siempre que sea posible.

## Configuración del teclado

El teclado numérico utilizado actualmente se identifica mediante:

```text
VID: 0x1A2C
PID: 0x0B2A
```

Estos valores se utilizan con AutoHotInterception para evitar que las acciones del controlador respondan a otros teclados.

Si se utiliza otro teclado, será necesario obtener su VID/PID y actualizar la configuración correspondiente.

## Control de volumen

El sistema utiliza un estado local del volumen y un temporizador de AutoHotkey para ejecutar los fades progresivamente.

Los parámetros principales son:

```ini
[Audio]

Mute=-100
Canto=-12
Max=0
FadeDuration=2000
FadeSteps=40
```

El fade utiliza una interpolación con curva S:

```ahk
progress := fadeCurrentStep / fadeSteps
curve := 3 * progress ** 2 - 2 * progress ** 3
```

Esto permite obtener una transición más suave que una interpolación lineal.

### `SetTimer`

Los fades utilizan `SetTimer()` en lugar de un bucle bloqueante con `Sleep`.

Esto permite que el script continúe respondiendo mientras el fade está en ejecución y permite interrumpir un fade anterior para comenzar uno nuevo.

## Dependencias de terceros

No modificar directamente las librerías ubicadas en `Lib/` salvo que exista una razón clara y documentada.

La lógica específica del proyecto debe mantenerse, siempre que sea posible, dentro de `numpad_obs.ahk`.

Esto facilita:

* Actualizar las dependencias.
* Reinstalar el proyecto.
* Migrarlo a otro equipo.
* Identificar qué código pertenece al proyecto y qué código pertenece a terceros.

## Configuración y secretos

Nunca realizar commits que contengan:

* Contraseñas.
* Tokens.
* Claves privadas.
* Credenciales de OBS.
* Otros secretos.

La configuración pública debe mantenerse en `config.ini`.

Las credenciales locales deben mantenerse en:

```text
password.ini
```

Este archivo está incluido en `.gitignore`.

La plantilla:

```text
password.example.ini
```

sí puede versionarse.

## Pruebas

Antes de utilizar cambios en una transmisión real:

1. Abrir OBS.
2. Ejecutar el controlador.
3. Verificar la conexión.
4. Probar cada escena.
5. Probar los tres niveles de volumen.
6. Interrumpir un fade y comprobar que el nuevo fade responde correctamente.
7. Comprobar el comportamiento al cerrar OBS.
8. Verificar que el teclado numérico sea el único dispositivo que activa las acciones.

Las pruebas deben realizarse preferentemente primero de forma aislada y después integradas.

## Commits

Se recomienda utilizar mensajes de commit descriptivos.

Ejemplos:

```text
feat: add configurable scene mappings
fix: prevent fade timer from running after completion
refactor: simplify volume fade logic
docs: update installation instructions
```

Para una nueva versión:

```text
feat: release v1.0.0 - initial stable version
```

## Versionado

El proyecto utiliza versionado semántico:

```text
MAJOR.MINOR.PATCH
```

Ejemplo:

```text
1.0.0
```

* **MAJOR**: cambios incompatibles.
* **MINOR**: nuevas funcionalidades compatibles.
* **PATCH**: correcciones y cambios menores.

## Pull Requests

Los cambios deberían:

* Tener un objetivo claro.
* Mantener el alcance limitado.
* Evitar modificaciones innecesarias de dependencias.
* Incluir documentación cuando sea necesario.
* Ser probados antes de integrarse.

## Principios del proyecto

Al realizar cambios se prioriza:

1. **Simplicidad**
2. **Confiabilidad durante transmisiones**
3. **Configuración externa**
4. **Baja dependencia del operador**
5. **Facilidad de mantenimiento**
6. **Separación entre código propio y dependencias de terceros**
