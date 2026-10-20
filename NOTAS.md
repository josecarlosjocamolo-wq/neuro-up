# Neuro Up — Notas para sustentar el proyecto

> Documento de respuestas para defensa con el jefe de carrera: **qué se hizo, cómo y por qué.**

---

## 1. En una frase

App Flutter multiplataforma de productividad y bienestar para personas neurodivergentes (TDAH) que, en su versión original, usaba Supabase (backend en la nube) y fue **migrada a SQLite local**, conservando el login con Google y añadiendo un chat con IA real.

---

## 2. Cómo se hizo (proceso paso a paso)

### Etapa 0 — Diagnóstico
1. `flutter analyze` + `grep`/búsqueda para encontrar todas las referencias a `supabase_flutter` (páginas, servicios, modelos).
2. Listado de bugs conocidos: el contador de tiempo de enfoque se **sobrescribía** (no sumaba), stats del Home/Perfil **hardcodeadas**, filtros de logros sin dueño de usuario, ids `int` que rompían la UI.

### Etapa 1 — Dependencias
3. Quité `supabase_flutter` del `pubspec.yaml`.
4. Añadí: `sqflite` (SQLite en móvil), `sqflite_common_ffi` (SQLite nativo en Windows), `path_provider`, `path`, `crypto` (sha256).

### Etapa 2 — Capa de datos local
5. `lib/data/local_db.dart`: singleton con `openDatabase`; `ensureInitialized()` usa `databaseFactoryFfi` en escritorio y `databaseFactorySqflite` en móvil. Esquema: `users`, `profiles`, `user_tasks`, `user_stats`, `user_settings`, `user_achievements`, `chat_messages`, `calendar_events`.
6. Reescribí los servicios para que hablen con SQL en vez de PostgREST: `auth_service`, `user_service`, `task_service`, `stats_service`, `pomodoro_service`, `achievement_service`.
7. **Migración de mentes de cada fila**: en Postgres los ids eran `int`, en la UI se esperaban `String` → migré el modelo a `String` para no romper el Home.

### Etapa 3 — Autenticación
8. `AuthService.init()` lee la sesión guardada en SharedPreferences (`current_user_id`).
9. Registro/login local: contraseña con **salt derivada del email** (`email::neuro_up::password`) y `sha256` → el hash se guarda, nunca la contraseña.
10. **Google Sign-In** se mantuvo: crea/recupera la cuenta local (`provider='google'`) sin password. OAuth hace el trabajo pesado del lado de Google.
11. Actualicé `main.dart`, `splash_screen`, `login_page`, `registro_page`, `home_page`, `perfil_page`, `editar_perfil_page`, `calendario_page`, `chat_bot_page`, `chat_service`.

### Etapa 4 — Bugs funcionales
12. Tiempo de enfoque: `UPDATE ... SET focus_time_seconds = focus_time_seconds + ?` en vez de asignar (se acumula entre sesiones).
13. Home/Perfil: reemplacé números inventados por consultas reales (`stats_service`) — creé tarjetas de foco en Perfil con datos existentes que antes nadie usaba.
14. Filtrado de logros/estadísticas **por usuario** (antes mezclaba cuentas).
15. Lint único introducido por mi (`dead_null_aware_expression` en `user_service.dart`) → corregido.

### Etapa 5 — Chat con IA
16. `AiService`: API **compatible con OpenAI** (estándar de facto). Config por `--dart-define` (`AI_API_KEY`, `AI_BASE_URL`, `AI_MODEL`) o runtime en SharedPreferences; defaults `https://api.openai.com/v1` / `gpt-4o-mini`.
17. Sin clave → **motor de reglas local contextual**, para que el chat nunca quede roto.
18. UI: estado "IA activa / Modo local", diálogo de configuración que precarga los valores guardados.

### Etapa 6 — Accesibilidad para TDAH
19. `lib/theme/app_prefs.dart`: persiste tema y Modo Calma entre sesiones; `AppPrefs.reduceMotion()` combina Modo Calma + ajuste "reducir movimiento" del sistema.
20. Helper `_motion()` en el Home: apaga los brillos ambientales repetidos y la animación de UPI cuando se pide movimiento reducido.
21. Corregidos lints de contexto tras `async` (no rompen, pero son malas prácticas).

### Etapa 7 — Verificación
22. `flutter analyze` → **0 errores** (265 avisos info/warning, prácticamente todos preexistentes).
23. `flutter build bundle` → EXIT=0.
24. Android emulado (API 36): APK instalado y lanzado; flujo splash → login → registro, **sin crash, sin MissingPluginException, sin errores de sqflite**.
25. `flutter build apk --debug` → OK; luego `flutter build apk --release` → OK (145 MB; también disponible `--split-per-abi` ≈ 50 MB).

---

## 3. La pregunta clave: ¿Por qué dejaste Supabase?

**Fase 1 — por qué se usó inicialmente**
- Supabase es *backend as a service*: base de datos Postgres, autenticación, APIs REST automáticas y almacenamiento, **sin montar servidor propio**.
- Estandariza desde el día 1: relacionales, políticas RLS, dashboard web.
- Como equipo nuevo en el tema, eliminaba todo el backend y nos dejaba enfocarnos en la UI y la lógica de negocio.

**Fase 2 — por qué se reemplazó (la respuesta que hay que dar con seguridad)**
- **La app debe funcionar sin internet.** Es una herramienta de productividad diaria para TDAH: si para listar tareas dependes de la red, la app falla justo cuando más se necesita. SQLite local es instantáneo y siempre disponible.
- **Simplicidad de operación:** un solo dispositivo, una sola fuente de verdad, sin cuentas de servicio, sin planes gratuitos con límite, sin claves que filtrar, sin caídas de terceros.
- **Aislamiento de datos:** nada sale del dispositivo.
- **Costo:** sin costo de infraestructura ni complejidad de despliegue.

**El trade-off que asumo en voz alta (esto impresiona más que esconderlo)**
- ❌ No hay sincronización multi-dispositivo ni varios usuarios en la nube.
- ✅ Sí hay: offline total, privacidad, respuesta instantánea, cero costo.
- 🔄 Si se quisiera sincronización, se reinsertaría una capa `SynchronizationService` (sincronización diferida por ID/UUID) **con** Supabase, sin tocar el resto de la app — la arquitectura con repositorios/services lo permite. Los UUID a favor de eso.

---

## 4. Tabla de decisiones "¿por qué cada cosa?"

| Decisión | Por qué |
|---|---|
| SQLite en vez de Hive/Isar | Es SQL relacional (mismo modelo mental que Postgres), permite consultas/filtros agregados y era un refactor directo desde Supabase. |
| `sqflite_common_ffi` en escritorio | `sqflite` puro no existe para Windows; FFI empaqueta el mismo SQLite nativo → mismo código en todas las plataformas. |
| IDs `String` (UUID) | Los `int` locales no coincidían entre tablas/consultas y rompían el Home; UUID colisionan improbablemente y facilitan futuro sync. |
| Session en SharedPreferences | Es lo mínimo para "recordar quién entró" sin re-login. |
| Contraseña: sha256 + salt | Almacenar en claro es inaceptable; salt por usuario evita rainbow tables y que el mismo password dé el mismo hash. |
| Google OAuth en vez de solo local | Login clásico para el usuario, sin que veamos/guardemos su contraseña, y con extrañas de verificación. |
| Tiempo de enfoque que **suma** | Bug original: cada sesión destruía el historial → datos no confiables, justo lo contrario de una app para monitoreo. |
| Stats reales vs. mockups | Si la app miente en los números, no sirve para autorregulación. |
| IA compatible con OpenAI | Estandar de facto → funciona con OpenAI, LM Studio, Ollama, etc., cambiando 2 textfields. Cero dependencia de un proveedor. |
| La API key **nunca** en el repo | Se inyecta por `--dart-define`/runtime. Un APK reverse-engineerable no puede contener secretos. |
| Fallback local de reglas | El chat no debe dejar de responder solo porque no haya internet o credenciales. |
| Persistir tema y Modo Calma | Ajustes de accesibilidad que se pierden al reiniciar son un fallo de diseño para el usuario objetivo. |
| `reduceMotion()` + `_motion()` | Animación continua/parpadeos distraen y pueden marear; además respeta el toggle global del SO (estándar de accesibilidad). |
| APK release sin certificado propio | Es un proyecto académico; el certificado de producción (y su costo/gestión) no aporta aquí. |

---

## 5. Preguntas difíciles probables (y respuesta corta)

**¿Por qué no Firebase, por qué Supabase?**
Ambos son BaaS. Elegí Supabase por ser Postgres (SQL relacional que conocía del curso) y por su tier gratuito generoso. Luego, por el mismo motivo de "sin backend", lo removí.

**¿Es seguro?**
Contraseñas con hash + salt; google_id de referencia; la API key de IA no viaja en el APK. La sesión es local y revocable con "Cerrar sesión".

**¿Y los datos si cambio de teléfono?**
No hay backup/sync. Es el trade-off explícito de este diseño. Se podría agregar exportar/importar JSON o un proveedor de nube.

**¿Cómo probaste la migración si no había datos reales en Supabase?**
El esquema local es la fuente de verdad nueva; validé creación/lectura/escritura por código y por la app en el emulador (login y navegación). La migración de filas existentes se cubriría con un `MigrationService` si hubiera producción con datos.

**¿Dónde está la "ventaja TDAH"?** (si te pregunta qué la hace específica)
- Ajuste de **Modo Calma** persistente que realmente reduce animaciones.
- Respeto de *reducir movimiento* del sistema.
- Filtros y tipos de prueba, navegación de 4-5 destinos claros, una acción primaria por pantalla.

**¿Por qué Dart/Flutter?**
Un solo código para Android y Windows (y Web iónicamente), UI declarativa y rápido para iterar — encaja con un proyecto de carrera con recursos limitados.

**¿Dónde está la documentación?**
`lib/` está comentado por responsabilidad (services / pages / theme / data); este archivo resume arquitectura y decisiones.

---

## 6. Cómo demostrarlo en vivo (30 segundos)

1. Mostrar el código de `focus_time_seconds = focus_time_seconds + ?` (bug corregido).
2. Abrir el APK, loguearte y navegar a Perfil → ver cifras reales de enfoque/tests.
3. Activar Modo Calma y volver al Home → desaparecen los brillos/animación.
4. Chat: mostrar chip "IA activa / Modo local" y el diálogo de configuración (prueba que la IA no es hardcodeada).

---

## 6.5 Seguridad y secretos (pregunta muy probable)

**Estado tras la revisión:** **cero claves secretas en el código fuente.**

| Qué se revisó | Resultado |
|---|---|
| Clave `service_role` de Supabase | ❌ No existe en el proyecto (Supabase ya fue retirado) |
| Anon key / JWT de Supabase (`eyJ...`) | ❌ No está en ningún archivo |
| URL `*.supabase.co` | ❌ No aparece (solo comentarios en Markdown) |
| Clave de API del chat (`sk-...`) | ❌ No está hardcodeada; se inyecta por `--dart-define` o la escribe el usuario en la app |
| Contraseñas de bases de datos | ❌ No hay; la DB es SQLite local y solo se guarda `password_hash` |
| Keystores de firma (`*.jks`, `key.properties`) | ❌ No hay ninguno en el repositorio |

**Cómo está organizado:**

- **`.env.example`** → se sube a git. Plantilla con valores **vacíos** y comentarios explicativos.
- **`.env`** → local, en `.gitignore`. Aquí viven tus claves reales.
- **`.gitignore`** → ignora `.env`, `.env.*` (excepto `.env.example`), `google-services.json`, `*.jks`, `*.keystore`, `key.properties`, `*.p12`, `*.mobileprovision`.
- **`scripts/flutter-env.ps1`** → lee `.env` y lo traduce a `--dart-define=...`. Ejecución: `.\scripts\flutter-env.ps1 build apk -Mode release`.
- Verificado con `git init` en una copia temporal: los archivos que se subirían son solo `.env.example`, `.gitignore`, `NOTAS.md` y `google-services.json.example`.

**Regla clave que hay que saber defender:** una clave **dentro del APK** siempre es extraíble (se descompila). Por eso la app **no distribuye la clave de IA**: cada usuario la introduce en *Ajustes del chat > Clave de IA* y se guarda solo en **su** dispositivo. La opción de `.env`/`--dart-define` es solo para builds de desarrollo propio.

**Advertencia honesta:** existe `android/app/google-services.json` con una API key de Firebase/Google (`AIzaSy...`) usada por `firebase_core` y `firebase_messaging`. Esa clave **sí se ignora en git** (solo se sube la plantilla), y aun así Google exige restringirla en Google Cloud Console → *Application restrictions: Android apps* con el nombre del paquete (`com.example.neuro_up`) y el SHA-1 del keystore.

---

## 7. Entregables

- Proyecto: `...\Default Project\neuro_up`
- APK release: `build\app\outputs\flutter-apk\app-release.apk` (y copia `NeuroUp.apk` en Escritorio)
- Secretos: `.env.example` (subido) / `.env` (local, ignorado)
- Sin referencias a Supabase en `lib/` (salvo comentarios)
- Estado: `flutter analyze` 0 errores; build bundle y APK OK; app corriendo en emulador sin excepciones.
