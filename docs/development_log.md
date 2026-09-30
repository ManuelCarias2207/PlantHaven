# PlantHaven — Development Log

## 1. Visión General

**PlantHaven** es una aplicación Flutter que se conecta a una API RESTful con base de datos PostgreSQL en Neon. El primer módulo a implementar es el de **Autenticación** (Login + Registro).

---

## 2. Arquitectura

### 2.1 Patrón: Clean Architecture + MVVM

Utilizamos **Clean Architecture** para separar responsabilidades en capas independientes, combinada con **MVVM** (Model-View-ViewModel) en la capa de presentación para gestionar el estado de forma reactiva.

```
┌─────────────────────────────────────────────────────┐
│                  PRESENTATION                        │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │    Pages     │  │  ViewModels  │  │  Widgets   │ │
│  │ (UI Screens) │  │ (State Mgmt) │  │(Reusable)  │ │
│  └─────────────┘  └──────────────┘  └────────────┘ │
├─────────────────────────────────────────────────────┤
│                    DOMAIN                            │
│  ┌─────────────┐  ┌──────────────┐                  │
│  │  Entities   │  │ Repositories │  │  Use Cases   │ │
│  │  (Models)   │  │ (Abstract)   │  │ (Business)   │ │
│  └─────────────┘  └──────────────┘                  │
├─────────────────────────────────────────────────────┤
│                     DATA                             │
│  ┌─────────────┐  ┌──────────────┐                  │
│  │   Models    │  │ Repositories │  │  DataSources │ │
│  │  (DTO/JSON) │  │   (Impl)     │  │  (API/Mock)  │ │
│  └─────────────┘  └──────────────┘                  │
└─────────────────────────────────────────────────────┘
```

### 2.2 Flujo de Datos

```
UI (Page) → ViewModel → UseCase → Repository (abstract) → RepositoryImpl → DataSource → API/Mock
```

---

## 3. Estructura de Archivos

```
lib/
├── main.dart                          # Punto de entrada
├── core/                              # Código transversal a features
│   ├── constants/
│   │   ├── app_colors.dart            # Paleta de colores PlantHaven
│   │   ├── app_strings.dart           # Textos centralizados
│   │   └── app_routes.dart            # Nombres de rutas
│   ├── errors/
│   │   └── failures.dart              # Clases de error/fallo
│   ├── network/
│   │   └── network_info.dart          # Verificación de conectividad
│   ├── routes/
│   │   └── app_router.dart            # Configuración de rutas (GoRouter)
│   └── utils/
│       └── validators.dart            # Validadores reutilizables
├── features/
│   └── auth/                          # Módulo de Autenticación
│       ├── data/
│       │   ├── datasources/
│       │   │   └── auth_remote_datasource.dart   # Mock API Neon
│       │   ├── models/
│       │   │   └── user_model.dart               # DTO de usuario
│       │   └── repositories/
│       │       └── auth_repository_impl.dart     # Implementación
│       ├── domain/
│       │   ├── entities/
│       │   │   └── user.dart                     # Entidad de dominio
│       │   ├── repositories/
│       │   │   └── auth_repository.dart          # Contrato abstracto
│       │   └── usecases/
│       │       ├── login.dart                    # Caso de uso: login
│       │       └── register.dart                 # Caso de uso: registro
│       └── presentation/
│           ├── viewmodels/
│           │   └── auth_viewmodel.dart           # Estado + lógica VM
│           ├── pages/
│           │   ├── login_page.dart               # Pantalla Login
│           │   └── register_page.dart            # Pantalla Registro
│           └── widgets/
│               ├── auth_card.dart                # Tarjeta blanca redondeada
│               ├── auth_text_field.dart          # Campo de texto sin bordes
│               ├── auth_button.dart              # Botón píldora con flecha
│               └── password_strength_indicator.dart  # Check contraseña
└── injection_container.dart           # Inyección de dependencias (get_it)
```

---

## 4. Paleta de Colores PlantHaven

| Token | Hex | Uso |
|-------|-----|-----|
| `background` | `#F8F6EF` | Fondo general crema claro |
| `primary` | `#0A3B22` | Botones principales, textos destacados |
| `fieldBackground` | `#EFECE1` | Fondos de campos de texto |
| `accent` | `#4A7055` | Detalles en verde oliva |
| `white` | `#FFFFFF` | Tarjetas, texto sobre primario |
| `error` | `#B3261E` | Mensajes de error |
| `textPrimary` | `#1C1B1F` | Texto principal |
| `textSecondary` | `#49454F` | Texto secundario |

---

## 5. Decisiones Técnicas

| Aspecto | Decisión | Justificación |
|---------|----------|---------------|
| Gestión de estado | `ChangeNotifier` + `provider` | Ligero, nativo de Flutter, suficiente para el módulo |
| Inyección de dependencias | `get_it` | Simple, ampliamente usado |
| Enrutado | `go_router` | Declarativo, soporta guards de auth |
| Tipografía | `GoogleFonts` (Inter o similar) | Sin serifas, limpia |
| Validadores | Clases puras en `core/utils` | Testeables, reutilizables |
| API Mock | `Future.delayed` + datos hardcodeados | Simula latencia y respuestas de Neon |

---

## 6. Historias de Usuario — Módulo Auth

### HU-01: Inicio de Sesión
- **Como** usuario registrado
- **Quiero** ingresar mi correo y contraseña
- **Para** acceder al catálogo principal de PlantHaven

**Criterios de aceptación:**
- Validación de campos obligatorios
- Mostrar "Credenciales inválidas" si el login falla
- Guardar token JWT en almacenamiento seguro
- Redirigir al catálogo (`/catalog`) tras login exitoso

### HU-02: Registro de Cuenta
- **Como** nuevo usuario
- **Quiero** crear una cuenta con mis datos personales
- **Para** poder usar PlantHaven

**Criterios de aceptación:**
- Nombres y apellidos en una sola fila
- Teléfono con prefijo +503 predeterminado
- Validación visual de contraseña: mínimo 8 caracteres, letras y números
- Checkbox de términos y condiciones obligatorio
- Manejo de errores por datos duplicados (correo/teléfono ya registrados)

### HU-03: Recuperar Contraseña
- **Como** usuario que olvidó su contraseña
- **Quiero** un enlace para recuperarla
- **Para** restablecer el acceso a mi cuenta

### HU-04: Protección de Rutas (Guard)
- **Como** aplicación
- **Quiero** proteger rutas que requieren autenticación
- **Para** evitar acceso no autorizado

**Criterios de aceptación:**
- Si no hay token válido → redirigir a `/login`
- Si hay token válido → permitir acceso a rutas protegidas

---

## 7. Plan de Implementación

| Fase | Tarea | Estado |
|------|-------|--------|
| 1 | Documento de desarrollo | ✅ Completado |
| 2 | Componentes reutilizables (widgets) | ⏳ En progreso |
| 3 | UI — Pantallas Login y Registro | ⏳ Pendiente |
| 4 | Lógica de estado (ViewModel + Mock API) | ⏳ Pendiente |
| 5 | Guard de rutas | ⏳ Pendiente |

---

## 8. Notas

- La API mock simula latencia de red con `Future.delayed`
- El token se almacena en memoria (futuro: `flutter_secure_storage`)
- Las respuestas del backend siguen el formato: `{ "success": bool, "data": ..., "message": ... }`
- Los errores de datos duplicados se manejan con mensajes específicos del backend
