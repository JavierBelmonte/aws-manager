# Design Document: AWS Profile Widget

## Overview

El widget de AWS Profile para macOS es una aplicación nativa construida con SwiftUI y WidgetKit que permite a los usuarios visualizar y cambiar entre perfiles de AWS directamente desde el Notification Center o el escritorio. El widget lee y modifica el archivo `~/.aws/credentials` de forma segura, proporcionando una interfaz visual para la funcionalidad existente en `aws_tui.py`.

## Architecture

El sistema se compone de tres capas principales:

```
┌─────────────────────────────────────┐
│      Widget UI (SwiftUI)            │
│  - Small/Medium/Large Layouts       │
│  - Profile Display                  │
│  - Profile Selection                │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Widget Extension (WidgetKit)      │
│  - Timeline Provider                │
│  - Widget Configuration             │
│  - Update Scheduling                │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  Credentials Manager (Swift)        │
│  - File I/O Operations              │
│  - INI Parser                       │
│  - Profile Management               │
└─────────────────────────────────────┘
```

### Componentes Principales

1. **Widget UI Layer**: Interfaz visual usando SwiftUI
2. **Widget Extension**: Lógica de actualización y timeline usando WidgetKit
3. **Credentials Manager**: Backend para leer/escribir credenciales
4. **App Intents**: Manejo de interacciones del usuario (cambio de perfil)

## Components and Interfaces

### 1. AWSCredentialsManager

Responsable de todas las operaciones de lectura y escritura del archivo de credenciales.

```swift
class AWSCredentialsManager {
    static let shared = AWSCredentialsManager()
    private let credentialsPath: URL
    
    // Lee todos los perfiles del archivo credentials
    func loadProfiles() -> [AWSProfile]
    
    // Obtiene el perfil activo actual (default)
    func getActiveProfile() -> AWSProfile?
    
    // Cambia el perfil activo copiando credenciales a default
    func setActiveProfile(profileName: String) throws
    
    // Crea backup del archivo credentials
    func createBackup() throws
    
    // Parsea el archivo INI de credenciales
    private func parseCredentialsFile() -> [String: [String: String]]
}
```

### 2. AWSProfile

Modelo de datos para representar un perfil de AWS.

```swift
struct AWSProfile: Identifiable, Codable {
    let id: String              // Nombre del perfil
    let name: String            // Nombre para mostrar
    let accessKeyId: String     // AWS Access Key (parcial)
    let isActive: Bool          // Si es el perfil activo
    let lastUpdated: Date       // Última actualización
    
    // Retorna versión enmascarada de la access key
    var maskedAccessKey: String {
        return String(accessKeyId.prefix(4)) + "..."
    }
}
```

### 3. WidgetTimelineProvider

Proveedor de timeline para actualizar el widget periódicamente.

```swift
struct AWSProfileTimelineProvider: TimelineProvider {
    typealias Entry = AWSProfileEntry
    
    // Snapshot para preview
    func placeholder(in context: Context) -> AWSProfileEntry
    
    // Snapshot rápido para transiciones
    func getSnapshot(in context: Context, completion: @escaping (AWSProfileEntry) -> Void)
    
    // Timeline de actualizaciones
    func getTimeline(in context: Context, completion: @escaping (Timeline<AWSProfileEntry>) -> Void)
}
```

### 4. AWSProfileEntry

Entrada de timeline que contiene el estado del widget.

```swift
struct AWSProfileEntry: TimelineEntry {
    let date: Date
    let activeProfile: AWSProfile?
    let availableProfiles: [AWSProfile]
    let errorMessage: String?
}
```

### 5. SwitchProfileIntent

App Intent para manejar el cambio de perfil desde el widget.

```swift
struct SwitchProfileIntent: AppIntent {
    static var title: LocalizedStringResource = "Switch AWS Profile"
    
    @Parameter(title: "Profile Name")
    var profileName: String
    
    func perform() async throws -> some IntentResult
}
```

### 6. Widget Views

Vistas para diferentes tamaños de widget.

```swift
// Vista pequeña: solo perfil activo
struct SmallWidgetView: View {
    let entry: AWSProfileEntry
    var body: some View
}

// Vista mediana: perfil activo + lista compacta
struct MediumWidgetView: View {
    let entry: AWSProfileEntry
    var body: some View
}

// Vista grande: perfil activo + lista completa
struct LargeWidgetView: View {
    let entry: AWSProfileEntry
    var body: some View
}
```

## Data Models

### Archivo de Credenciales (~/.aws/credentials)

Formato INI estándar de AWS:

```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[profile1]
aws_access_key_id = AKIAI44QH8DHBEXAMPLE
aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY

[profile2]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE2
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY2
```

### Shared Data Container

Para compartir datos entre el widget y la app principal (si existe):

```swift
let sharedContainer = UserDefaults(suiteName: "group.com.awsmanager.widget")
```

Datos almacenados:
- `lastActiveProfile`: String - Nombre del último perfil activo
- `lastUpdateTime`: Date - Última vez que se actualizó
- `profileCache`: Data - Cache de perfiles para carga rápida

## Correctness Properties

*Una propiedad es una característica o comportamiento que debe mantenerse verdadero en todas las ejecuciones válidas del sistema - esencialmente, una declaración formal sobre lo que el sistema debe hacer. Las propiedades sirven como puente entre las especificaciones legibles por humanos y las garantías de corrección verificables por máquina.*


### Property 1: Active Profile Identification
*For any* archivo de credenciales válido con una sección "default", el widget debe identificar correctamente qué perfil está activo comparando las credenciales de "default" con las de otros perfiles, y mostrar el nombre del perfil coincidente.
**Validates: Requirements 1.1, 1.2**

### Property 2: Timestamp Presence
*For any* estado del widget con un perfil activo, el modelo de datos debe incluir un timestamp de última actualización.
**Validates: Requirements 1.5**

### Property 3: Complete Profile Parsing
*For any* archivo de credenciales válido, el parser debe extraer todos los perfiles definidos en el archivo sin pérdida de información.
**Validates: Requirements 2.1**

### Property 4: Default Profile Filtering
*For any* lista de perfiles extraídos del archivo de credenciales, la lista mostrada al usuario no debe contener el perfil "default".
**Validates: Requirements 2.2**

### Property 5: Active Profile Marking
*For any* lista de perfiles con un perfil activo identificado, exactamente un perfil debe estar marcado como activo (isActive = true).
**Validates: Requirements 2.4**

### Property 6: Alphabetical Ordering
*For any* lista de perfiles disponibles, los perfiles deben estar ordenados alfabéticamente por nombre.
**Validates: Requirements 2.5**

### Property 7: Profile Switch Correctness
*For any* perfil seleccionado para activación, después de ejecutar el cambio, las credenciales en la sección "default" deben ser idénticas a las credenciales del perfil seleccionado.
**Validates: Requirements 3.1**

### Property 8: Backup Creation
*For any* operación de modificación del archivo de credenciales, debe existir un archivo de backup (.bak) después de la operación.
**Validates: Requirements 3.2, 5.4**

### Property 9: Error State Preservation
*For any* operación de cambio de perfil que falla, el contenido del archivo de credenciales debe permanecer idéntico al estado anterior al intento de cambio.
**Validates: Requirements 3.4, 6.4**

### Property 10: Model Update After Switch
*For any* cambio de perfil exitoso, el modelo de datos del widget debe reflejar el nuevo perfil activo inmediatamente después de la operación.
**Validates: Requirements 3.5**

### Property 11: Credentials Path Consistency
*For any* operación de lectura o escritura de credenciales, el path utilizado debe ser siempre ~/.aws/credentials.
**Validates: Requirements 5.1**

### Property 12: Credential Masking
*For any* credencial (access key o secret key) mostrada en el widget, debe estar enmascarada mostrando solo los primeros 4 caracteres seguidos de "..." y nunca la credencial completa.
**Validates: Requirements 5.2, 5.3**

### Property 13: Corrupted File Handling
*For any* archivo de credenciales con formato INI inválido o corrupto, el parser debe detectar el error y retornar un estado de error sin crashear.
**Validates: Requirements 6.3**

## Error Handling

### Error Types

1. **FileNotFoundError**: Archivo ~/.aws/credentials no existe
   - Acción: Mostrar mensaje "Credentials file not found"
   - Recovery: Sugerir crear el archivo o configurar AWS CLI

2. **PermissionError**: Sin permisos de lectura/escritura
   - Acción: Mostrar mensaje "Permission denied"
   - Recovery: Sugerir verificar permisos del archivo

3. **ParseError**: Formato INI inválido
   - Acción: Mostrar mensaje "Invalid credentials format"
   - Recovery: Sugerir verificar sintaxis del archivo

4. **WriteError**: Error al escribir cambios
   - Acción: Restaurar desde backup, mostrar error
   - Recovery: Verificar espacio en disco y permisos

5. **BackupError**: No se puede crear backup
   - Acción: Abortar operación, no modificar archivo original
   - Recovery: Verificar espacio en disco

### Error Handling Strategy

```swift
enum CredentialsError: Error {
    case fileNotFound
    case permissionDenied
    case invalidFormat(String)
    case writeFailed(String)
    case backupFailed(String)
}

extension CredentialsError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Credentials file not found at ~/.aws/credentials"
        case .permissionDenied:
            return "Permission denied accessing credentials file"
        case .invalidFormat(let details):
            return "Invalid credentials format: \(details)"
        case .writeFailed(let details):
            return "Failed to write credentials: \(details)"
        case .backupFailed(let details):
            return "Failed to create backup: \(details)"
        }
    }
}
```

### Logging Strategy

Usar `os.log` de Apple para logging estructurado:

```swift
import os.log

let logger = Logger(subsystem: "com.awsmanager.widget", category: "credentials")

// Ejemplos de uso:
logger.info("Loading profiles from credentials file")
logger.error("Failed to parse credentials: \(error.localizedDescription)")
logger.debug("Switching to profile: \(profileName)")
```

## Testing Strategy

### Dual Testing Approach

Este proyecto utilizará tanto **unit tests** como **property-based tests** para garantizar la corrección del código:

- **Unit tests**: Verificarán ejemplos específicos, casos de borde y condiciones de error
- **Property tests**: Verificarán propiedades universales a través de múltiples entradas generadas aleatoriamente

Ambos tipos de tests son complementarios y necesarios para una cobertura comprehensiva.

### Property-Based Testing Framework

Usaremos **SwiftCheck** (https://github.com/typelift/SwiftCheck) como biblioteca de property-based testing para Swift. SwiftCheck es un port de QuickCheck para Swift y proporciona generadores automáticos para tipos comunes.

### Test Configuration

- Cada property test debe ejecutar **mínimo 100 iteraciones** para asegurar cobertura adecuada
- Cada test debe estar etiquetado con un comentario referenciando la propiedad del diseño:
  ```swift
  // Feature: aws-profile-widget, Property 1: Active Profile Identification
  func testActiveProfileIdentification() { ... }
  ```

### Test Structure

```swift
import XCTest
import SwiftCheck
@testable import AWSProfileWidget

class AWSCredentialsManagerTests: XCTestCase {
    
    // MARK: - Unit Tests
    
    func testLoadProfilesWithEmptyFile() {
        // Test edge case: empty credentials file
    }
    
    func testLoadProfilesWithNoDefault() {
        // Test edge case: no default profile
    }
    
    func testSetActiveProfileCreatesBackup() {
        // Test specific example of backup creation
    }
    
    // MARK: - Property-Based Tests
    
    // Feature: aws-profile-widget, Property 3: Complete Profile Parsing
    func testCompleteProfileParsing() {
        property("All profiles in credentials file are parsed") <- forAll { (profiles: [String: Credentials]) in
            // Generate random credentials file
            // Parse it
            // Verify all profiles are present
            return parsedProfiles.count == profiles.count
        }
    }
    
    // Feature: aws-profile-widget, Property 6: Alphabetical Ordering
    func testAlphabeticalOrdering() {
        property("Profiles are always sorted alphabetically") <- forAll { (profiles: [AWSProfile]) in
            let sorted = manager.sortProfiles(profiles)
            return sorted == sorted.sorted { $0.name < $1.name }
        }
    }
    
    // Feature: aws-profile-widget, Property 12: Credential Masking
    func testCredentialMasking() {
        property("Credentials are always masked correctly") <- forAll { (accessKey: String) in
            guard accessKey.count >= 4 else { return Discard() }
            let masked = AWSProfile.maskCredential(accessKey)
            return masked.hasPrefix(String(accessKey.prefix(4))) && 
                   masked.hasSuffix("...") &&
                   masked.count == 7
        }
    }
}
```

### Custom Generators

Para property-based testing, necesitaremos generadores personalizados:

```swift
extension String: Arbitrary {
    // Generator para AWS Access Keys (formato: AKIA + 16 caracteres)
    static func arbitraryAWSAccessKey() -> Gen<String> {
        return Gen.compose { c in
            let chars = c.generate(using: Gen.fromElements(in: "A"..."Z") + Gen.fromElements(in: "0"..."9"))
            return "AKIA" + String(chars.prefix(16))
        }
    }
}

extension AWSProfile: Arbitrary {
    public static var arbitrary: Gen<AWSProfile> {
        return Gen.compose { c in
            AWSProfile(
                id: c.generate(),
                name: c.generate(),
                accessKeyId: c.generate(using: String.arbitraryAWSAccessKey()),
                isActive: c.generate(),
                lastUpdated: Date()
            )
        }
    }
}
```

### Integration Tests

Además de unit y property tests, se incluirán tests de integración para:

1. **Widget Timeline**: Verificar que el timeline se actualiza correctamente
2. **App Intents**: Verificar que los intents de cambio de perfil funcionan end-to-end
3. **File System**: Verificar operaciones reales de lectura/escritura en archivos temporales

### Test Coverage Goals

- **Credentials Manager**: 90%+ cobertura de código
- **Profile Models**: 100% cobertura (modelos simples)
- **Widget Views**: 70%+ cobertura (UI testing limitado)
- **App Intents**: 85%+ cobertura

## Implementation Notes

### macOS Permissions

El widget necesitará permisos para:
- Leer/escribir en `~/.aws/credentials`
- Acceso a App Groups para compartir datos

Configuración en `Info.plist`:
```xml
<key>NSHomeDirectoryUsageDescription</key>
<string>Access AWS credentials file to manage profiles</string>
```

### Widget Refresh Strategy

- **Automático**: Cada 5 minutos usando Timeline
- **Manual**: Usuario puede forzar refresh desde el widget
- **File Watcher**: Idealmente usar FSEvents para detectar cambios en el archivo

### Performance Considerations

- Cache de perfiles en UserDefaults para carga rápida
- Parsing asíncrono del archivo de credenciales
- Límite de 10 perfiles mostrados en widget large (scroll si hay más)

### Compatibility

- **Mínimo**: macOS 13.0 (Ventura)
- **Recomendado**: macOS 14.0+ (Sonoma) para mejores features de WidgetKit
- **Swift**: 5.9+
- **Xcode**: 15.0+
