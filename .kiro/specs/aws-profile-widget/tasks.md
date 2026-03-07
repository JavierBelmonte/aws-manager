# Implementation Plan: AWS Profile Widget

## Overview

Este plan implementa un widget nativo de macOS usando Swift, SwiftUI y WidgetKit para gestionar perfiles de AWS. La implementación se divide en capas: modelo de datos, gestor de credenciales, widget UI, y testing comprehensivo.

## Tasks

- [x] 1. Configurar proyecto Xcode y estructura base
  - Crear nuevo proyecto de Widget Extension en Xcode
  - Configurar App Group para compartir datos: `group.com.awsmanager.widget`
  - Configurar permisos en Info.plist para acceso a archivos
  - Agregar SwiftCheck como dependencia para property-based testing
  - _Requirements: 4.1, 4.2_

- [-] 2. Implementar modelo de datos AWSProfile
  - [x] 2.1 Crear struct AWSProfile con propiedades requeridas
    - Implementar Identifiable, Codable, Equatable
    - Agregar computed property `maskedAccessKey`
    - _Requirements: 5.2, 5.3_
  
  - [ ]* 2.2 Escribir property test para enmascaramiento de credenciales
    - **Property 12: Credential Masking**
    - **Validates: Requirements 5.2, 5.3**
  
  - [ ]* 2.3 Escribir unit tests para casos de borde del modelo
    - Test con access keys cortas (< 4 caracteres)
    - Test con access keys vacías
    - _Requirements: 5.2, 5.3_

- [x] 3. Implementar AWSCredentialsManager - Parsing
  - [x] 3.1 Crear clase AWSCredentialsManager con singleton pattern
    - Implementar inicialización con credentialsPath
    - Definir enum CredentialsError con todos los casos
    - _Requirements: 5.1, 6.1, 6.2, 6.3_
  
  - [x] 3.2 Implementar parseCredentialsFile() para leer formato INI
    - Parser de formato INI básico (secciones y key=value)
    - Manejo de comentarios y líneas vacías
    - Retornar diccionario [String: [String: String]]
    - _Requirements: 2.1_
  
  - [ ]* 3.3 Escribir property test para parsing completo
    - **Property 3: Complete Profile Parsing**
    - **Validates: Requirements 2.1**
  
  - [ ]* 3.4 Escribir property test para manejo de archivos corruptos
    - **Property 13: Corrupted File Handling**
    - **Validates: Requirements 6.3**
  
  - [ ]* 3.5 Escribir unit tests para casos de error de parsing
    - Test con archivo no existente
    - Test con archivo sin permisos
    - Test con archivo vacío
    - _Requirements: 6.1, 6.2_

- [x] 4. Implementar AWSCredentialsManager - Operaciones de lectura
  - [x] 4.1 Implementar loadProfiles() para cargar todos los perfiles
    - Llamar a parseCredentialsFile()
    - Convertir diccionario a array de AWSProfile
    - Filtrar perfil "default"
    - Ordenar alfabéticamente
    - _Requirements: 2.1, 2.2, 2.5_
  
  - [x] 4.2 Implementar getActiveProfile() para identificar perfil activo
    - Leer credenciales de sección "default"
    - Comparar con otros perfiles para encontrar coincidencia
    - Retornar perfil coincidente o nil
    - _Requirements: 1.1, 1.2, 2.4_
  
  - [ ]* 4.3 Escribir property test para filtrado de default
    - **Property 4: Default Profile Filtering**
    - **Validates: Requirements 2.2**
  
  - [ ]* 4.4 Escribir property test para ordenamiento alfabético
    - **Property 6: Alphabetical Ordering**
    - **Validates: Requirements 2.5**
  
  - [ ]* 4.5 Escribir property test para identificación de perfil activo
    - **Property 1: Active Profile Identification**
    - **Validates: Requirements 1.1, 1.2**
  
  - [ ]* 4.6 Escribir property test para marcado de perfil activo
    - **Property 5: Active Profile Marking**
    - **Validates: Requirements 2.4**

- [x] 5. Checkpoint - Verificar parsing y lectura
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Implementar AWSCredentialsManager - Operaciones de escritura
  - [x] 6.1 Implementar createBackup() para crear archivo .bak
    - Copiar archivo credentials a credentials.bak
    - Manejar errores de escritura
    - _Requirements: 3.2, 5.4_
  
  - [x] 6.2 Implementar setActiveProfile() para cambiar perfil activo
    - Validar que el perfil existe
    - Crear backup antes de modificar
    - Copiar credenciales del perfil a sección "default"
    - Escribir archivo actualizado
    - Manejar rollback en caso de error
    - _Requirements: 3.1, 3.4, 6.4_
  
  - [ ]* 6.3 Escribir property test para creación de backup
    - **Property 8: Backup Creation**
    - **Validates: Requirements 3.2, 5.4**
  
  - [ ]* 6.4 Escribir property test para corrección del cambio de perfil
    - **Property 7: Profile Switch Correctness**
    - **Validates: Requirements 3.1**
  
  - [ ]* 6.5 Escribir property test para preservación de estado en errores
    - **Property 9: Error State Preservation**
    - **Validates: Requirements 3.4, 6.4**
  
  - [ ]* 6.6 Escribir unit tests para casos de error de escritura
    - Test con disco lleno (simulado)
    - Test con permisos insuficientes
    - _Requirements: 6.4_

- [x] 7. Implementar logging con os.log
  - Crear Logger con subsystem y category apropiados
  - Agregar logging en operaciones críticas (load, parse, switch)
  - Agregar logging de errores con detalles
  - _Requirements: 6.5_

- [x] 8. Checkpoint - Verificar operaciones de escritura
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Implementar AWSProfileEntry y TimelineProvider
  - [x] 9.1 Crear struct AWSProfileEntry conforme a TimelineEntry
    - Agregar propiedades: date, activeProfile, availableProfiles, errorMessage
    - Implementar inicializadores
    - _Requirements: 1.1, 2.1_
  
  - [x] 9.2 Crear AWSProfileTimelineProvider conforme a TimelineProvider
    - Implementar placeholder() con datos de ejemplo
    - Implementar getSnapshot() para preview rápido
    - Implementar getTimeline() con refresh cada 5 minutos
    - Manejar errores y mostrar en errorMessage
    - _Requirements: 1.4, 4.7_
  
  - [ ]* 9.3 Escribir unit tests para TimelineProvider
    - Test de placeholder
    - Test de snapshot
    - Test de timeline con diferentes estados
    - _Requirements: 4.7_

- [x] 10. Implementar SwitchProfileIntent
  - [x] 10.1 Crear struct SwitchProfileIntent conforme a AppIntent
    - Definir parámetro profileName
    - Implementar perform() para cambiar perfil
    - Manejar errores y retornar resultado apropiado
    - _Requirements: 3.1, 3.4_
  
  - [ ]* 10.2 Escribir property test para actualización del modelo
    - **Property 10: Model Update After Switch**
    - **Validates: Requirements 3.5**
  
  - [ ]* 10.3 Escribir unit tests para AppIntent
    - Test de cambio exitoso
    - Test de cambio con perfil inexistente
    - Test de cambio con error de escritura
    - _Requirements: 3.1, 3.4_

- [x] 11. Implementar Widget Views - Small Size
  - [x] 11.1 Crear SmallWidgetView con SwiftUI
    - Mostrar solo nombre del perfil activo
    - Mostrar timestamp de última actualización
    - Manejar estado sin perfil activo
    - Aplicar estilos y colores del sistema
    - _Requirements: 1.1, 1.5, 4.4, 4.6_
  
  - [ ]* 11.2 Escribir unit tests para SmallWidgetView
    - Test con perfil activo
    - Test sin perfil activo
    - Test con error
    - _Requirements: 4.4_

- [x] 12. Implementar Widget Views - Medium Size
  - [x] 12.1 Crear MediumWidgetView con SwiftUI
    - Mostrar perfil activo en la parte superior
    - Mostrar lista compacta de 3-4 perfiles disponibles
    - Agregar botones/links para cambiar perfil
    - Indicar visualmente el perfil activo en la lista
    - _Requirements: 2.2, 2.4, 4.5, 4.6_
  
  - [ ]* 12.2 Escribir unit tests para MediumWidgetView
    - Test con múltiples perfiles
    - Test con perfil activo marcado
    - _Requirements: 4.5_

- [x] 13. Implementar Widget Views - Large Size
  - [x] 13.1 Crear LargeWidgetView con SwiftUI
    - Mostrar perfil activo con más detalles
    - Mostrar lista completa de perfiles (hasta 10)
    - Mostrar access key enmascarada para cada perfil
    - Agregar botones para cambiar perfil
    - _Requirements: 2.2, 2.4, 4.5, 4.6, 5.2_
  
  - [ ]* 13.2 Escribir unit tests para LargeWidgetView
    - Test con lista completa de perfiles
    - Test con más de 10 perfiles
    - _Requirements: 4.5_

- [x] 14. Implementar Widget principal y configuración
  - [x] 14.1 Crear struct principal del Widget
    - Configurar supportedFamilies: [.systemSmall, .systemMedium, .systemLarge]
    - Implementar body con switch para diferentes tamaños
    - Configurar displayName y description
    - _Requirements: 4.3_
  
  - [x] 14.2 Configurar Widget en WidgetBundle
    - Registrar widget en el bundle
    - Configurar Info.plist con permisos necesarios
    - _Requirements: 4.1, 4.2_

- [x] 15. Checkpoint - Verificar UI y funcionalidad completa
  - Ensure all tests pass, ask the user if questions arise.

- [x] 16. Implementar cache en UserDefaults
  - [x] 16.1 Crear extensión de UserDefaults para App Group
    - Implementar métodos para guardar/cargar perfiles cacheados
    - Implementar métodos para guardar/cargar último perfil activo
    - Implementar métodos para guardar/cargar timestamp
    - _Requirements: 1.5_
  
  - [ ]* 16.2 Escribir property test para timestamp presence
    - **Property 2: Timestamp Presence**
    - **Validates: Requirements 1.5**
  
  - [ ]* 16.3 Escribir unit tests para cache
    - Test de guardar y cargar perfiles
    - Test de expiración de cache
    - _Requirements: 1.5_

- [ ] 17. Implementar property test para consistencia de path
  - [ ]* 17.1 Escribir property test para path de credenciales
    - **Property 11: Credentials Path Consistency**
    - **Validates: Requirements 5.1**

- [ ] 18. Tests de integración end-to-end
  - [ ]* 18.1 Escribir test de integración completo
    - Crear archivo de credenciales temporal
    - Cargar perfiles
    - Cambiar perfil activo
    - Verificar cambio en archivo
    - Limpiar archivos temporales
    - _Requirements: 3.1, 3.2, 3.5_
  
  - [ ]* 18.2 Escribir test de integración con Timeline
    - Verificar que Timeline se actualiza correctamente
    - Verificar que cambios en archivo se reflejan en widget
    - _Requirements: 1.4, 4.7_

- [ ] 19. Checkpoint final - Verificar todos los tests
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 20. Documentación y README
  - Crear README.md con instrucciones de instalación
  - Documentar cómo agregar el widget a macOS
  - Documentar requisitos del sistema
  - Agregar screenshots del widget en diferentes tamaños
  - _Requirements: 4.1_

## Notes

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia los requisitos específicos para trazabilidad
- Los checkpoints aseguran validación incremental
- Los property tests validan propiedades de corrección universales
- Los unit tests validan ejemplos específicos y casos de borde
- SwiftCheck se usará para property-based testing con mínimo 100 iteraciones por test
