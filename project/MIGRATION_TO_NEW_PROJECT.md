# Migración a Nuevo Proyecto Supabase "BINGOS"

## Paso 1: Crear Nuevo Proyecto en Supabase

1. Ve a [Supabase Dashboard](https://supabase.com/dashboard)
2. Haz clic en "New Project"
3. Nombre del proyecto: **BINGOS**
4. Establece una contraseña de base de datos segura (guárdala)
5. Selecciona una región cercana a tus usuarios
6. Haz clic en "Create new project"
7. Espera a que el proyecto se aprovisione (2-3 minutos)

## Paso 2: Obtener Credenciales del Nuevo Proyecto

Una vez que el proyecto esté listo:

1. Ve a **Settings** → **API**
2. Copia los siguientes valores:
   - **Project URL** (empieza con `https://`)
   - **anon/public key** (bajo "Project API keys")
   - **service_role key** (bajo "Project API keys" - mantener secreto)

## Paso 3: Actualizar Variables de Entorno

Reemplaza las credenciales en tu archivo `.env`:

```env
VITE_SUPABASE_URL=tu_nueva_project_url
VITE_SUPABASE_ANON_KEY=tu_nueva_anon_key
SUPABASE_SERVICE_ROLE_KEY=tu_nueva_service_role_key
```

## Paso 4: Ejecutar Script de Migración

Ve al **SQL Editor** en tu nuevo proyecto de Supabase y ejecuta el script completo que se encuentra en:

`supabase/complete_migration.sql`

Este script incluye:
- ✅ Todas las tablas (user_profiles, game_modes, rooms, games, etc.)
- ✅ Todas las políticas RLS
- ✅ Todas las funciones necesarias
- ✅ Todos los índices para rendimiento
- ✅ Todos los triggers

## Paso 5: Configurar Seguridad del Auth

En el nuevo proyecto, ve a **Authentication** → **Providers** → **Email**:

1. **Enable email provider** ✓
2. **Confirm email**: Deshabilitado (o habilitado según prefieras)

Ve a **Authentication** → **URL Configuration**:
- Configura tu **Site URL** (ej: `http://localhost:5173` para desarrollo)
- Agrega **Redirect URLs** necesarias

Ve a **Authentication** → **Auth Providers** → **Email Auth**:
- Habilita **Captcha protection** si lo deseas

## Paso 6: Crear Usuario Admin

Después de ejecutar el script de migración:

1. Registra un nuevo usuario en tu aplicación
2. Ve al **SQL Editor** en Supabase
3. Ejecuta este comando para hacer al usuario admin:

```sql
UPDATE user_profiles
SET role = 'admin'
WHERE id = 'ID_DEL_USUARIO_AQUI';
```

Para obtener el ID del usuario, puedes ejecutar:

```sql
SELECT id, full_name FROM user_profiles;
```

## Paso 7: Verificar la Migración

1. Inicia tu aplicación: `npm run dev`
2. Registra/inicia sesión con el usuario admin
3. Verifica que el panel de admin funcione
4. Crea un modo de juego de prueba
5. Crea una sala de prueba
6. Prueba unirte a un juego

## Notas Importantes

- ⚠️ **NO ejecutes este script en tu proyecto actual** - es para el nuevo proyecto
- ✅ Los usuarios tendrán un balance inicial de $100
- ✅ El costo de entrada por defecto es $10
- ✅ Todas las tablas tienen RLS habilitado
- ✅ Solo los admins pueden crear salas y modos de juego
- ✅ Los jugadores pueden ver solo sus propios datos y juegos en los que participan

## ¿Problemas?

Si encuentras errores:

1. Verifica que las credenciales en `.env` sean correctas
2. Asegúrate de que el script de migración se ejecutó completamente sin errores
3. Verifica que el usuario tenga rol 'admin' en la base de datos
4. Revisa los logs en **Database** → **Logs** en Supabase Dashboard
