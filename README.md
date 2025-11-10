# TesiXpress (Flutter)

**UI en español, código en inglés y comentarios en español.**  
Analiza tesis (PDF/DOCX) con Gemini y guarda chats en Supabase.

## Quickstart

1) Flutter 3.22+  
2) Edita `lib/services/supabase_service.dart` con tu `supabaseUrl` y `supabaseAnonKey`.  
3) Coloca tu clave Gemini en `lib/screens/chat/chat_screen.dart` (`YOUR_GEMINI_API_KEY`).  
4) En Supabase, ejecuta `supabase_schema.sql`.  
5) `flutter pub get` y `flutter run`.

## Notas

- Colores base: amarillo, blanco, beige.  
- APA = azul. IEEE = rojo.  
- La barra de preguntas aparece **solo** tras el primer análisis.  
