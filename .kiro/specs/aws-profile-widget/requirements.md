# Requirements Document

## Introduction

Un widget nativo para macOS que permite cambiar rápidamente entre perfiles de AWS y visualizar el perfil activo actual. El widget se integra con el sistema de widgets de macOS (Notification Center) y proporciona acceso rápido a la gestión de perfiles sin necesidad de abrir una terminal.

## Glossary

- **Widget**: Componente visual de macOS que se muestra en el Notification Center o en el escritorio
- **AWS_Profile**: Configuración de credenciales de AWS almacenada en ~/.aws/credentials
- **Active_Profile**: El perfil AWS configurado como "default" en el archivo de credenciales
- **Profile_Switcher**: Componente del widget que permite seleccionar y activar diferentes perfiles
- **Credentials_Manager**: Módulo backend que lee y modifica el archivo ~/.aws/credentials

## Requirements

### Requirement 1: Visualización del Perfil Activo

**User Story:** Como usuario de AWS, quiero ver el perfil activo actual en el widget, para saber qué cuenta estoy usando sin abrir la terminal.

#### Acceptance Criteria

1. WHEN el widget se carga, THE Widget SHALL mostrar el nombre del perfil activo actual
2. WHEN el perfil default existe en ~/.aws/credentials, THE Widget SHALL extraer y mostrar su nombre basándose en las credenciales que coincidan
3. WHEN no existe un perfil default, THE Widget SHALL mostrar "No active profile"
4. WHEN el archivo de credenciales cambia, THE Widget SHALL actualizar la visualización del perfil activo dentro de 5 segundos
5. THE Widget SHALL mostrar la última vez que se actualizó el perfil activo

### Requirement 2: Listado de Perfiles Disponibles

**User Story:** Como usuario de AWS, quiero ver todos mis perfiles disponibles en el widget, para poder cambiar rápidamente entre ellos.

#### Acceptance Criteria

1. WHEN el widget se carga, THE Widget SHALL leer todos los perfiles desde ~/.aws/credentials
2. THE Widget SHALL mostrar una lista de todos los perfiles excepto "default"
3. WHEN no existen perfiles configurados, THE Widget SHALL mostrar un mensaje "No profiles configured"
4. THE Widget SHALL indicar visualmente cuál es el perfil activo actual en la lista
5. THE Widget SHALL ordenar los perfiles alfabéticamente

### Requirement 3: Cambio de Perfil

**User Story:** Como usuario de AWS, quiero cambiar el perfil activo desde el widget, para no tener que usar comandos de terminal.

#### Acceptance Criteria

1. WHEN un usuario selecciona un perfil de la lista, THE Profile_Switcher SHALL copiar las credenciales de ese perfil a la sección "default"
2. WHEN se cambia el perfil, THE Credentials_Manager SHALL crear un backup del archivo credentials antes de modificarlo
3. WHEN el cambio de perfil es exitoso, THE Widget SHALL mostrar una notificación de confirmación
4. IF ocurre un error al cambiar el perfil, THEN THE Widget SHALL mostrar un mensaje de error y mantener el perfil anterior
5. WHEN se cambia el perfil, THE Widget SHALL actualizar inmediatamente la visualización del perfil activo

### Requirement 4: Integración con macOS

**User Story:** Como usuario de macOS, quiero que el widget se integre nativamente con el sistema, para tener una experiencia consistente con otras aplicaciones.

#### Acceptance Criteria

1. THE Widget SHALL ser compatible con macOS 13 (Ventura) o superior
2. THE Widget SHALL utilizar WidgetKit framework de Apple
3. THE Widget SHALL soportar los tamaños de widget: small, medium, y large
4. WHEN el widget está en tamaño small, THE Widget SHALL mostrar solo el perfil activo
5. WHEN el widget está en tamaño medium o large, THE Widget SHALL mostrar el perfil activo y la lista de perfiles disponibles
6. THE Widget SHALL usar el tema del sistema (light/dark mode)
7. THE Widget SHALL actualizar su contenido usando Timeline de WidgetKit

### Requirement 5: Persistencia y Seguridad

**User Story:** Como usuario preocupado por la seguridad, quiero que el widget maneje mis credenciales de forma segura, para proteger mi información sensible.

#### Acceptance Criteria

1. THE Widget SHALL leer credenciales solo desde ~/.aws/credentials
2. THE Widget SHALL nunca mostrar las claves de acceso completas (access keys o secret keys)
3. WHEN se muestra información de credenciales, THE Widget SHALL mostrar solo los primeros 4 caracteres seguidos de "..."
4. THE Credentials_Manager SHALL crear un archivo .bak antes de cualquier modificación
5. THE Widget SHALL tener permisos de lectura y escritura solo en ~/.aws/credentials

### Requirement 6: Manejo de Errores

**User Story:** Como usuario, quiero que el widget maneje errores de forma clara, para entender qué salió mal y cómo solucionarlo.

#### Acceptance Criteria

1. IF el archivo ~/.aws/credentials no existe, THEN THE Widget SHALL mostrar "Credentials file not found"
2. IF el archivo ~/.aws/credentials no tiene permisos de lectura, THEN THE Widget SHALL mostrar un mensaje de error de permisos
3. IF el archivo ~/.aws/credentials está corrupto, THEN THE Widget SHALL mostrar "Invalid credentials format"
4. WHEN ocurre un error al escribir el archivo, THE Widget SHALL mantener el estado anterior y notificar al usuario
5. THE Widget SHALL registrar errores en el sistema de logs de macOS para debugging
