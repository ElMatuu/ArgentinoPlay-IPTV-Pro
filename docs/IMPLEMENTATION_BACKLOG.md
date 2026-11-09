# Auditoría y backlog de implementación — ArgentinoPlay IPTV Pro

**Actualización de estado:** 2026-11-09  
**Rama base de referencia:** `main`  
**Commit de main verificado:** `cc2df1e91e237b8d5fd8bdf08d8f74570cb4127b`

> Esta actualización complementa la auditoría histórica que sigue debajo. Los estados de PR/CI cambian con cada commit; no deben interpretarse como integración en `main` mientras no exista un merge aprobado.

## Estado actual verificado

- La rama `main` tiene una ejecución de CI exitosa (#21, run `42534462677`), pero no contiene todavía las funcionalidades de las PR #22–#25.
- PR #22: búsqueda de canales por país, idioma y metadatos EPG. CI exitoso en el commit `3baf96180d327086e26932fcf72905358a2e3623`.
- PR #23: visualización segura de logos M3U. CI exitoso en `a8a8e5e1bebfb01297e2f37b1417e8685fb4e721`.
- PR #24: búsqueda y filtros de programas EPG. CI exitoso en `cd84d5e54ed1f210ef1f3125c55381d8b934ff81`; incluye corrección de salto de línea en descripciones.
- PR #25: reemplazo seguro de fuentes de listas existentes. CI exitoso en `2aed2f256d6dd4dfbaed675669bf5d559e7205df`.
- PR #3–#7 y PR #9 siguen abiertas. Las PR #6 y #7 tienen conflictos/estado de base no limpio informado por GitHub y deben reconciliarse antes de revisión final. PR #7 depende de PR #6; PR #6 depende de la configuración y decisiones de PR #5. No fusionarlas fuera de orden.
- Issue #1 sigue abierto como registro principal de aceptación y fases.
- El workflow de CI ejecuta formato, análisis estático, pruebas, build Android debug y publicación de artefacto. El APK de CI es de depuración, no un APK/AAB release firmado.
- El directorio Android se genera en CI y `pubspec.lock` no estaba presente en `main` en esta revisión; ambos son pendientes de reproducibilidad.
- CI verde no equivale a validación en un teléfono o Android TV físico. La prueba real de reproducción, navegación D-pad y compatibilidad de streams autorizados sigue pendiente en hardware.
- La integración Supabase no debe darse por completa por la existencia de PRs o secretos. La aplicación debe continuar funcionando localmente sin configuración cloud. Solo URL del proyecto y publishable key pueden llegar al cliente; nunca claves secret/service-role, tokens administrativos o contraseñas.

## Próximas acciones priorizadas

1. Mantener PR #22–#25 sin fusionar hasta que el propietario revise y apruebe cada cambio; verificar nuevamente sus checks al momento de la revisión.
2. Reconciliar PR #3–#7 en orden de dependencia: documentación/modelo (#3), arquitectura local-first (#4), migración y RLS (#5), bootstrap opcional (#6), autenticación (#7). Resolver conflictos actualizando ramas contra la base actual sin pisar cambios.
3. Hacer reproducible el build: incorporar un `pubspec.lock` generado por Flutter y decidir/documentar el scaffold Android versionado; mantener versiones de Flutter, Java y SDK explícitas.
4. Completar pruebas adversariales de M3U/XMLTV, persistencia y operaciones interrumpidas.
5. Mejorar reproductor y recuperación de red con pruebas de regresión.
6. Validar Android TV con D-pad y dispositivo/emulador real.
7. Completar revisión de privacidad, dependencias, licencias y proceso de release firmado por el propietario.

## Reglas de aceptación

- No declarar una función terminada por estar documentada o por existir en una rama: debe estar integrada, probada y documentada.
- No ocultar pruebas fallidas, desactivar tests ni sustituir pruebas útiles por pruebas triviales.
- No hacer push directo a `main`, auto-merge ni publicar releases sin aprobación explícita.
- No usar streams, logos ni guías sin autorización verificable.
- Separar claramente resultados CI, pruebas de emulador y pruebas en hardware real.
- Cada PR debe indicar alcance, archivos modificados, riesgos, comandos/checks ejecutados y limitaciones.

---

## Registro histórico de auditoría — 2026-11-08

**Corte de auditoría:** 2026-11-08  
**Rama auditada:** `main`  
**Commit base:** `74b9deba1a82fb112bf21a797043317a8ea02e5c`

Este documento separa las funciones que ya existen de las que siguen pendientes. Una función no se considera terminada por estar mencionada en el README: debe estar implementada, probada y validada en un dispositivo compatible.

## Estado ejecutivo

- El repositorio contiene un cliente Flutter funcional en etapa temprana, con importación local de listas M3U/M3U8 y guías XMLTV, favoritos, búsqueda, administración de varias listas y reproducción de red básica.
- La integración continua de la rama principal todavía no ha demostrado una compilación APK exitosa. En la ejecución auditada fallaron dos pruebas de widgets de administración de listas; por ello se omitieron la compilación y la publicación del APK.
- El proyecto todavía no es una versión de producción ni una aplicación terminada para Android TV.
- La arquitectura local-first está documentada. La sincronización cloud, las cuentas y Supabase siguen siendo trabajo en ramas/PRs separados; no se encontró evidencia de un proyecto Supabase desplegado o conectado.
- No se deben incluir listas de canales sin autorización, claves administrativas, tokens personales, contraseñas ni URLs con credenciales en el cliente o en el repositorio.

## P0 — Bloqueos inmediatos

### P0.1 Estabilizar pruebas de administración de listas

**Estado:** pendiente de resolución verificada.

- Corregir la interacción de los tests con el menú contextual de cada lista.
- Mantener un repositorio en memoria para que los tests de widgets no dependan de operaciones reales de filesystem.
- Diagnosticar por qué el botón de acciones queda fuera del área de hit testing en el entorno de pruebas.
- Cubrir listado, renombrado, confirmación de borrado, borrado, selección y activación.
- No desactivar tests, no ignorar warnings de hit testing y no sustituir taps reales por callbacks directos sin documentar el alcance de la prueba.
- Criterio de salida: `flutter test --reporter expanded` completo en verde en CI.

### P0.2 Completar la puerta de CI y generar el APK

- Exigir formato sin modificar silenciosamente los archivos del runner: usar una comprobación equivalente a `dart format --output=none --set-exit-if-changed lib test`.
- Mantener `flutter analyze --fatal-infos --fatal-warnings`.
- Ejecutar todas las pruebas antes de compilar.
- Ejecutar `flutter build apk --debug` y subir el APK como artefacto verificable.
- Verificar el APK descargándolo e instalándolo en un dispositivo Android real.
- Criterio de salida: Android SDK, formato, análisis, pruebas, build y upload todos en verde.

### P0.3 Hacer reproducible el entorno Android

- El workflow actualmente genera el scaffolding Android durante CI. Revisar si se debe incorporar el directorio `android/` al repositorio para que el proyecto también se pueda compilar localmente sin pasos implícitos.
- Documentar versiones compatibles de Flutter, Dart, Java y Android SDK.
- Incorporar y mantener `pubspec.lock` para fijar las dependencias resueltas de la aplicación.
- Criterio de salida: una persona desarrolladora puede clonar el repositorio y reproducir el build siguiendo instrucciones versionadas.

## P1 — Calidad funcional del cliente

### P1.1 Reproductor multimedia

**Implementado:** reproducción básica de una URL de red, pausa/reproducción, barra de progreso, indicador de buffering, reintento manual y pausa/reanudación por ciclo de vida.

**Pendiente:**

- Matriz de compatibilidad probada para HLS, DASH y MP4 autorizados.
- Mensajes de error diferenciados y diagnóstico seguro, sin registrar URLs completas ni credenciales.
- Reconexión controlada y límites de reintentos.
- Selección de pistas de audio y subtítulos cuando el motor las soporte.
- Relación de aspecto, pantalla completa y controles de reproducción completos.
- Pruebas de sesiones largas, pérdida de conectividad y cambios de orientación.
- Criterio de salida: matriz de dispositivos/formatos publicada y pruebas de reproducción repetibles.

### P1.2 Administración de listas

**Implementado en el código auditado:** varias listas locales, listado, selección/activación, renombrado y eliminación; validación de nombre y límite de tamaño.

**Pendiente:**

- Reemplazar el contenido de una lista conservando o actualizando metadatos de forma segura.
- Detección y resolución de duplicados por identidad de fuente/contenido.
- Mostrar origen, fecha de importación, última actualización y estado de autorización declarado por el usuario.
- Confirmación y recuperación ante operaciones interrumpidas.
- Pruebas de corrupción de manifiesto, archivos faltantes, colisiones y fallos de escritura.
- Criterio de salida: operaciones CRUD completas, transaccionales y cubiertas por pruebas.

### P1.3 Importación y parsers

**Implementado:** importación local M3U/M3U8 y XMLTV; límites de tamaño de 5 MB y 10 MB; lectura de metadatos habituales; rechazo de esquemas no HTTP(S) y URLs con credenciales incrustadas.

**Pendiente:**

- Ampliar pruebas con archivos grandes, entradas malformadas, codificaciones y atributos poco habituales.
- Informar cuántas entradas fueron aceptadas, ignoradas o rechazadas y por qué.
- Validar nombres, metadatos, iconos y enlaces externos antes de mostrarlos.
- Evitar bloqueos de interfaz durante parseos grandes mediante trabajo fuera del hilo de UI cuando corresponda.
- Criterio de salida: pruebas de límites, entradas adversariales y rendimiento documentadas.

### P1.4 EPG/XMLTV

**Implementado:** importación manual, parseo de canales y programas, normalización de offsets horarios y consulta de programación por canal.

**Pendiente:**

- Búsqueda de programas y filtros por horario/categoría.
- Asistencia para vincular canales cuando `tvg-id` no coincide exactamente.
- Actualización programada y control de antigüedad de la guía.
- Rendimiento con guías grandes, programas duplicados y datos incompletos.
- Criterio de salida: guía validada con fixtures representativos y comportamiento correcto en zonas horarias.

## P1 — Android TV y accesibilidad

- Navegación completa con D-pad: arriba, abajo, izquierda, derecha, aceptar y atrás.
- Estados de foco visibles y orden de foco predecible.
- Controles de reproducción accesibles desde control remoto.
- Diseño para paisaje, pantallas grandes y distancias de lectura de TV.
- Pruebas en Android TV/emulador y al menos un televisor o dispositivo físico compatible.
- Revisar contraste, escalado de texto, etiquetas semánticas y objetivos táctiles.
- Criterio de salida: checklist de aceptación Android TV aprobado.

## P2 — Seguridad, privacidad y derechos

- Mantener el funcionamiento local aunque no haya cuenta ni conexión.
- No tratar una URL pública como prueba de permiso para retransmitir. Usar únicamente fuentes propias, de dominio público o licenciadas para el uso previsto.
- No incluir listas de canales sin autorización.
- No añadir importación remota de URLs hasta implementar HTTPS obligatorio, límites de tamaño, timeout, límites de redirección y defensas SSRF contra loopback, redes privadas, link-local y direcciones reservadas.
- No guardar credenciales dentro de URLs ni imprimir URLs completas en logs.
- Revisar permisos Android, exportación de datos, política de privacidad, retención y borrado.
- Añadir análisis de dependencias, licencias y vulnerabilidades a CI.
- Criterio de salida: revisión de amenazas y privacidad documentada y sin hallazgos críticos abiertos.

## P2 — Arquitectura y mantenibilidad

- Descomponer el archivo monolítico `lib/main.dart` en módulos de presentación, navegación, reproductor, EPG, importación y estado.
- Mantener modelos de dominio independientes de Flutter y de proveedores cloud.
- Definir interfaces de repositorio y pruebas de contrato para persistencia.
- Evitar migraciones de almacenamiento sin copia, verificación de hashes/recuentos y rollback probado.
- Criterio de salida: módulos con responsabilidades claras y cobertura de pruebas para flujos críticos.

## P2 — Supabase y sincronización opcional

Las ramas y PRs existentes describen trabajo incremental para modelo de datos, esquema, bootstrap y autenticación. No asumir que están desplegados o integrados en `main`.

Orden recomendado:

1. Revisar y aprobar el modelo de datos y el esquema SQL.
2. Aplicar la migración en un proyecto de desarrollo, ejecutar pruebas de RLS y asesores de seguridad y verificar aislamiento entre cuentas.
3. Completar persistencia local transaccional y outbox antes de habilitar sincronización.
4. Implementar autenticación opcional, registro/revocación de dispositivos y recuperación de cuenta.
5. Añadir sincronización idempotente, cursores, tombstones, conflictos, reintentos y consentimiento explícito.
6. Probar modo sin conexión, reconexión, duplicados, conflictos, borrado de cuenta y revocación de dispositivos.

Reglas obligatorias:

- El cliente solo puede recibir la URL del proyecto y una publishable key.
- Nunca compilar service-role/secret keys, contraseñas de base de datos ni tokens personales en el APK.
- No subir cuerpos M3U/M3U8, URLs de streams ni datos sensibles por defecto.
- Aplicar RLS a todas las tablas expuestas y comprobar políticas de propiedad con usuarios distintos.
- No provisionar recursos pagos ni desplegar backend sin aprobación explícita del propietario.

## P2 — Distribución y mantenimiento

- Definir identificador de aplicación, nombre visible, iconos, versionado y política de actualizaciones.
- Configurar firma release fuera del repositorio mediante secretos protegidos.
- Crear build release APK/AAB separado del build debug.
- Probar instalación, actualización, desinstalación, permisos y recuperación.
- Definir notas de versión, procedimiento de publicación y rollback.
- Samsung Tizen y LG webOS requieren aplicaciones específicas; un APK Android no se instala directamente en esos sistemas.

## Estado de ramas y PRs observados durante esta auditoría

- PR #8: corrección de tests de administración de listas; debe permanecer abierto hasta que la CI esté completamente verde.
- PR #2: intento anterior de sincronización de tests; su CI también falló y su solución no debe duplicarse si PR #8 la reemplaza.
- PR #3: documentación del modelo de datos y secretos.
- PR #4: contratos y arquitectura local-first para sincronización.
- PR #5: esquema Supabase/RLS; requiere validación en un proyecto de desarrollo antes de uso.
- PR #6: bootstrap opcional de Supabase; draft y dependiente de configuración segura.
- PR #7: servicio de autenticación; draft y apilado sobre PR #6.

No fusionar PRs apilados fuera de orden. Volver a ejecutar CI contra la base actualizada después de integrar cada dependencia.

## Definición de terminado

Una función solo pasa a **terminada** cuando:

1. El código está integrado en la rama objetivo.
2. El análisis estático y el formato pasan.
3. Hay pruebas automatizadas relevantes y pasan.
4. La CI genera los artefactos esperados.
5. Se prueba en el dispositivo/plataforma objetivo cuando el comportamiento depende de hardware.
6. La documentación coincide con el comportamiento real.
