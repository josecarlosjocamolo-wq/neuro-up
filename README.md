# Neuro Up

> App Flutter para apoyar la organización y la productividad de estudiantes universitarios **neurodivergentes (TDAH)**.
> Flutter app that helps university students with ADHD plan tasks, focus, and track progress — **works 100% offline**.

---

## Características

- **Enfoque Pomodoro** con estadísticas reales acumuladas (sesiones, minutos, racha).
- **Gestor de tareas** con prioridad, fecha y filtrado por estado.
- **Agenda / calendario** sincronizada con las tareas.
- **Tests cognitivos** de atención, memoria y emoción, con resultados guardados por usuario.
- **Asistente de chat con IA** configurable (API compatible con OpenAI: OpenAI, Ollama, LM Studio, Groq…).
- **Gamificación**: XP, niveles, logros y stickers.
- **Accesibilidad**: modo calma persistente, respeto del ajuste del sistema "reducir movimiento", temas claro/oscuro.

## Decisiones técnicas (lo que más se pregunta en una entrevista)

| Decisión | Por qué |
|---|---|
| **SQLite local** en lugar de un backend en la nube | Es una herramienta personal de uso diario: debe responder al instante y funcionar **sin internet**. Cero costo de infraestructura, cero caídas de terceros, los datos no salen del dispositivo. |
| **sqflite_common_ffi** en escritorio | Mismo código y misma base de datos en Android y Windows; `sqflite` no existe para Windows y FFI lo habilita. |
| **IDs `String` (UUID)** | Los `int` locales colisionaban entre tablas y rompían el Home. Además facilitan una futura sincronización multi-dispositivo. |
| **Google Sign-In + hash `sha256` con salt** | Google usa OAuth: la app nunca ve ni almacena la contraseña. En el registro local se guarda solo el hash (nunca en claro). |
| **Chat IA vía API compatible con OpenAI** | No depende de un proveedor: se cambia de modelo o de proveedor editando dos campos. La clave **no va en el código ni en el APK**: la introduce el usuario en la app y se guarda solo en su dispositivo. |
| **Modo Calma + `reduceMotion`** | El público objetivo a menudo es sensible al movimiento constante; la app desactiva animaciones ambientales cuando se pide. |

## Stack

| Capa | Tecnología |
|---|---|
| UI | Flutter 3.35 / Dart 3.9 (Material 3) |
| Base de datos | SQLite (`sqflite`, `sqflite_common_ffi`) |
| Autenticación | Google Sign-In + credenciales locales con hash SHA-256 |
| IA | API compatible con OpenAI + motor de reglas local como respaldo |
| Notificaciones | Firebase Cloud Messaging |

## Seguridad

El repositorio **no contiene claves ni secretos**:

- Las variables sensibles viven en `.env`, que está en `.gitignore`; solo se publica la plantilla `.env.example` con valores vacíos.
- La configuración de Firebase (`google-services.json`) también está ignorada; solo se publica `google-services.json.example`.
- La clave de la API de IA no se empaqueta en el APK (cualquier APK se puede descompilar). Cada usuario la introduce en **Ajustes del chat**.

```bash
cp .env.example .env      # tus claves locales
.\scripts\flutter-env.ps1 build apk -Mode release   # inyecta .env como --dart-define
```

## Ejecución

Requisitos: [Flutter SDK 3.35+](https://docs.flutter.dev/get-started/install).

```bash
flutter pub get
flutter run                    # Android / emulador
flutter run -d windows         # Windows (requiere Visual Studio con "Desarrollo de escritorio C++")
```

Con claves del `.env` inyectadas:

```powershell
.\scripts\flutter-env.ps1 run -Mode debug
```

## Compilar APK

```bash
flutter build apk --release               # universal
flutter build apk --release --split-per-abi   # ~50 MB por arquitectura
```

## Plataformas

| Plataforma | Estado |
|---|---|
| Android | ✅ Compilado y probado (API 36) |
| Windows | ⚠️ Requiere Visual Studio C++ toolchain |
| iOS | 🔧 No probado aún |
| Web | ❌ No compatible (`dart:io` / `dart:ffi`) |

## Estructura

```
lib/
├── data/         # local_db.dart — esquema y conexión SQLite
├── services/     # auth, tareas, estadísticas, pomodoro, logros, IA
├── pages/        # pantallas (home, agenda, tests, chat, perfil…)
├── theme/        # tema, modo calma, persistencia de preferencias
└── widgets/      # componentes reutilizables (botones, tarjetas, UPI)
```

Más detalle sobre el proceso y las decisiones en [`NOTAS.md`](NOTAS.md).

## Licencia

MIT — ver [`LICENSE`](LICENSE).

## Autor

Jose Carlos Jocamolo · [@josecarlosjocamolo-wq](https://github.com/josecarlosjocamolo-wq)
