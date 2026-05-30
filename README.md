<div align="center">

# 🛒 Alexara

**Plataforma SaaS de E-commerce Multi-tenant para el mercado argentino.**

[![Backend: .NET 10](https://img.shields.io/badge/Backend-.NET%2010-512BD4?logo=dotnet)](https://dotnet.microsoft.com/)
[![Frontend: Next.js 16](https://img.shields.io/badge/Frontend-Next.js%2016-000000?logo=next.js)](https://nextjs.org/)
[![Database: PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-336791?logo=postgresql)](https://www.postgresql.org/)
[![Monorepo: Turborepo](https://img.shields.io/badge/Monorepo-Turborepo-EF4444?logo=turborepo)](https://turbo.build/)
[![Payments: Mercado Pago](https://img.shields.io/badge/Pagos-Mercado%20Pago-009EE3?logo=mercadopago)](https://www.mercadopago.com.ar/)

Alexara es una plataforma moderna y escalable que permite a emprendedores y comerciantes crear, personalizar y gestionar su propia tienda online de manera rápida, con integración nativa a Mercado Pago.

[Explorar Características](#-características-principales) • [Ver Arquitectura](#-arquitectura-del-monorepo) • [Empezar a Desarrollar](#-getting-started)

</div>

---

## ✨ Características Principales

- 🛍️ **Multi-Tenant Nativo:** Arquitectura diseñada para soportar múltiples tiendas y comerciantes de forma aislada y segura en una sola infraestructura.
- ⚡ **Performance Excepcional:** Frontends construidos con **Next.js 16** (App Router y SSR), garantizando velocidades de carga ultrarrápidas y un SEO óptimo.
- 🛡️ **Clean Architecture & CQRS:** Backend robusto en **ASP.NET Core 10** y **MediatR**, facilitando la mantenibilidad, pruebas y escalabilidad del código.
- 💳 **Integración con Mercado Pago:** Flujo de pagos adaptado y optimizado específicamente para el mercado argentino.
- 🧱 **Monorepo Modular:** Gestión eficiente del código fuente usando **Turborepo** y **pnpm workspaces**, compartiendo tipos, utilidades y componentes UI en todo el proyecto.

---

## 🛠️ Stack Tecnológico

| Área | Tecnologías |
| :--- | :--- |
| **Backend API** | ASP.NET Core 10, Entity Framework Core, PostgreSQL, MediatR, FluentValidation |
| **Frontend** | Next.js 16, TypeScript, React, Tailwind CSS |
| **Herramientas** | Turborepo, pnpm (v10+), ESLint, Prettier |
| **Infraestructura** | Mercado Pago SDK |

---

## 📦 Arquitectura del Monorepo

El proyecto está estructurado para escalar de manera eficiente, separando responsabilidades en distintas aplicaciones y compartiendo la lógica y el diseño a través de paquetes.

```text
alexara/
├── apps/
│   ├── 🛒 store/        # Storefront: Tienda pública orientada al cliente final
│   ├── 📊 dashboard/    # Panel del Comerciante: Para la gestión del catálogo y ventas
│   ├── ⚙️ admin/         # SuperAdmin: Panel global de Alexara para administrar tiendas
│   └── 🔌 api/           # Backend Centralizado: .NET API que orquesta el negocio
├── packages/
│   ├── 🧩 ui/           # Sistema de diseño: Componentes React (Tailwind) compartidos
│   ├── 🔣 types/        # Modelos, interfaces y esquemas de validación unificados
│   └── 🛠️ utils/        # Helpers, funciones comunes y utilidades cross-app
└── turbo.json          # Configuración de los flujos de Turborepo
```

---

## 🚀 Getting Started

Sigue estos pasos para levantar el ecosistema completo de Alexara en tu entorno de desarrollo local.

### 1. Prerrequisitos

Asegúrate de tener instalado:
- [Node.js](https://nodejs.org/) (v18+)
- [pnpm](https://pnpm.io/) (v10+)
- [.NET SDK](https://dotnet.microsoft.com/) (10.0)
- [Docker & Docker Compose](https://www.docker.com/) (Recomendado para la base de datos local)

### 2. Instalación de Dependencias

Clona el repositorio e instala todas las dependencias del monorepo desde la raíz:

```bash
git clone https://github.com/tu-usuario/alexara.git
cd alexara
pnpm install
```

### 3. Base de Datos Local (Docker Compose)

Para estandarizar el entorno y evitar la instalación manual de bases de datos, utilizamos Docker para PostgreSQL.

**1. Iniciar la base de datos en segundo plano:**
Desde la raíz del proyecto, ejecuta:
```bash
docker compose up -d
```
*Esto descargará PostgreSQL 16 Alpine, creará un volumen de datos persistente y levantará la base de datos `ecommerce_db` en el puerto `5432`.*

**2. Aplicar las migraciones de Entity Framework Core:**
Asegúrate de tener la herramienta global de EF Core:
```bash
dotnet tool install --global dotnet-ef
```
Luego corre las migraciones para generar las tablas y el esquema inicial en tu contenedor local de PostgreSQL:
```bash
dotnet ef database update --project apps/api/src/alexara.Infrastructure --startup-project apps/api/src/alexara.API
```

> [!TIP]
> **Manejo del ciclo de vida en Docker:**
> - `docker compose stop` — Apaga temporalmente el contenedor para liberar memoria RAM/CPU (los datos se conservan).
> - `docker compose start` — Vuelve a encender el contenedor que detuviste.
> - `docker compose down -v` — Remueve el contenedor y **resetea la base de datos a cero**, eliminando todas las tablas y datos del volumen.

### 4. Configuración de Variables de Entorno

**Para el Backend (.NET):**
El backend ya cuenta con el bloque de conexión por defecto apuntando a la base de datos de Docker en [appsettings.json](file:///home/ivan-romero-maurin/projects/volttacore/Alexara/apps/api/src/alexara.API/appsettings.json):
```json
"ConnectionStrings": {
  "DefaultConnection": "Host=localhost;Database=ecommerce_db;Username=postgres;Password=postgres"
}
```

**Para los Frontends (Next.js):**
Crea un archivo `.env.local` en cada una de las carpetas correspondientes (`apps/store`, `apps/dashboard`, `apps/admin`) e incluye la siguiente variable indicando el puerto de tu API local:

```env
NEXT_PUBLIC_API_URL=http://localhost:5203
```

### 5. Ejecutar el Proyecto

Puedes levantar todo o partes específicas del ecosistema:

**Levantar el Backend:**
```bash
# Abre una terminal nueva
cd apps/api/src/alexara.API
dotnet run
```

**Levantar los Frontends (vía Turborepo):**
```bash
# En la terminal principal, desde la raíz del proyecto
pnpm run dev
```

> **Tip:** También puedes correr los frontends de manera individual usando: `pnpm run dev:store`, `pnpm run dev:dashboard`, o `pnpm run dev:admin`.

---

## 📜 Comandos Disponibles

Desde la raíz del proyecto, Turborepo te permite orquestar todas las aplicaciones:

- `pnpm run dev` — Levanta los entornos de desarrollo para todas las aplicaciones web de forma concurrente.
- `pnpm run build` — Genera los builds de producción, optimizando las aplicaciones mediante la caché de Turbo.
- `pnpm run lint` — Analiza el código de todos los workspaces utilizando ESLint y las reglas definidas.

---

## 🤝 Contribuyendo

Las contribuciones son bienvenidas para mejorar Alexara.
Asegúrate de seguir los principios de la arquitectura establecida, mantener la tipificación estricta en TypeScript y ejecutar el linteo (`pnpm run lint`) antes de enviar un Pull Request.

## 📄 Licencia

Este proyecto está bajo la licencia **MIT**. Lee el archivo de licencia para obtener más detalles.

---
<div align="center">
  <i>Construido con pasión para potenciar el comercio digital.</i>
</div>