TesiXpress

Aplicación móvil (Flutter) para gestionar trabajos de grado y facilitar el flujo estudiante–asesor: registro e inicio de sesión, creación y seguimiento de avances, comentarios, y exportes básicos. Autenticación y persistencia con Supabase.

✨ Funcionalidades

Autenticación con Supabase: registro, login.

Perfil básico de usuario (Nombre/Email).

Gestión de entregas (entregables/bitácoras), con estados e historial.

Notificaciones locales (cuando aplica).

Soporte Android (APK / AAB). Web funciona para pruebas rápidas.

Nota: algunas secciones son opcionales/experimentales y pueden depender de claves de OpenAI.

🧭 Arquitectura (alto nivel)

Flutter (Dart) con estructura por capas:

presentation/ – pantallas, widgets y navegación.

core/ – configuración, inyección de dependencias, utilidades.

services/ o data/ – acceso a API/DB (Supabase) y repositorios.

core/supabase_client.dart – inicialización del cliente de Supabase.

config/env.dart – lectura de variables (por --dart-define o dotenv).

Clases clave

Supa (core/supabase_client.dart)
Encapsula la conexión con Supabase.

class Supa {
  static const String supabaseUrl = 'https://<project-ref>.supabase.co';
  static const String supabaseAnonKey = '<anon-public-key>';
  static late SupabaseClient client;

  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl.trim(), anonKey: supabaseAnonKey.trim());
    client = Supabase.instance.client;
  }
}


Uso:

await Supa.init();
final auth = Supa.client.auth;


Servicios/Repos (por ejemplo auth_service.dart)
Métodos de alto nivel para signup, login, logout, getSession(), etc., usando Supa.client.

Pantallas (presentation/pages/*.dart)

SignupPage / LoginPage – formularios con validaciones (contraseña, correo).

MainPage – home con navegación a módulos (entregables, perfil, historial).

HistoryPage – histórico de acciones/entregas.

Otras páginas específicas del proyecto.

Env (config/env.dart)
Centraliza variables inyectadas por --dart-define:

class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const openaiApiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
}

⚙️ Requisitos

Flutter 3.x

Android SDK + platform-tools (ADB)

Cuenta en Supabase (gratuita) y proyecto creado.

🔐 Configuración

En Supabase → Project Settings → API copia:

Project URL (formato https://<ref>.supabase.co)

anon public key

Inicia la app leyendo variables por --dart-define (recomendado):

flutter run \
 --dart-define=SUPABASE_URL=https://<tu-ref>.supabase.co \
 --dart-define=SUPABASE_ANON_KEY=eyJ... \
 --dart-define=OPENAI_API_KEY=


Nota:
(No use comillas ni espacios extra; no ponga / al final de la URL.)

Alternativa con dotenv:

.env

SUPABASE_URL=https://<tu-ref>.supabase.co
SUPABASE_ANON_KEY=eyJ...
OPENAI_API_KEY=


En el main.dart, carga dotenv y pásalo a Supa.init().

▶️ Ejecutar en desarrollo
flutter pub get
flutter run


Si usted usa Supa.init() en main(), asegúrate de llamar a:

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supa.init();
  runApp(const MyApp());
}

📦 Generar APK / AAB

APK (release):

flutter clean
flutter pub get
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://<tu-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...


AAB (para Play Store):

flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://<tu-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...


Si tus plugins te piden una NDK específica, fija en android/app/build.gradle.kts:

android {
  ndkVersion = "27.0.12077973"
}


Permisos Android (obligatorio): en android/app/src/main/AndroidManifest.xml

<uses-permission android:name="android.permission.INTERNET" />


(Esto ya esta incluido en tu repo; solo verifica que esté en el manifest de main/.)

📱 Instalación en el teléfono

Copia app-release.apk al dispositivo y ábrelo (permite orígenes desconocidos),
o usa ADB:

adb install build\app\outputs\flutter-apk\app-release.apk

👤 Flujo de usuario

Crear cuenta

Correo válido, contraseña que cumpla políticas (mín. 8–10 caracteres, mayúscula, número y carácter especial; ejemplo: Lina1234*).

Se invoca a POST /auth/v1/signup de Supabase.

Iniciar sesión

Email + contraseña → sesión Supabase y token almacenado localmente (seguro).

Home

Acceso a módulos (entregables, historial, perfil).

Acciones de lectura/escritura a tablas públicas/seguras vía RLS (Row Level Security) en Supabase (asegura que tus políticas RLS permitan al usuario leer/escribir solo lo suyo).

Cerrar sesión

Supa.client.auth.signOut() y limpieza de caché local.

📂 Organización del código (ejemplo)

lib/
 ├── config/
 │    └── env.dart
 ├── core/
 │    ├── supabase_client.dart
 │    └── injection_container.dart (si usas DI)
 ├── data/ (o services/)
 │    ├── auth_service.dart
 │    └── deliverables_service.dart
 ├── presentation/
 │    ├── pages/
 │    │    ├── login_page.dart
 │    │    ├── signup_page.dart
 │    │    ├── main_page.dart
 │    │    └── history_page.dart
 │    └── widgets/
 └── main.dart

🧪 Endpoints Supabase usados (base)

Auth

POST /auth/v1/signup

POST /auth/v1/token?grant_type=password (login)

POST /auth/v1/logout

REST (PostgREST)

GET/POST/PATCH /rest/v1/<tabla> con apikey + Authorization: Bearer <access_token>

Recuerda crear tus tablas (p. ej., deliverables, notes) y habilitar RLS con políticas adecuadas.

🛠️ Solución de problemas

ClientException: SocketException: Failed host lookup ... supabase.co (Android)

Verifica que el permiso INTERNET esté en AndroidManifest.xml de main/.

Revisa que SUPABASE_URL no tenga espacios ni saltos de línea y no termine en /.

Prueba en el navegador del teléfono https://<ref>.supabase.co.

Si no abre, es la red/DNS/VPN del dispositivo. Cambia a datos móviles, desactiva VPN/Proxy y en DNS privado pon Automático.

Reinstala limpio: adb uninstall <applicationId>, flutter clean, flutter build apk.

NDK mismatch en build

Fija ndkVersion = "27.0.12077973" en build.gradle.kts.

Login no persiste

Asegura que guardas/restauras la sesión con Supa.client.auth.
