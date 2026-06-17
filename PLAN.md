# tw-ai-toolkit — Plan de Trabajo

> Estado: BORRADOR | Versión: 0.1 | Fecha: 2026-06-16

---

## Vision

Convertir `tw-ai-toolkit` en una super-herramienta enterprise de AI accesible desde cualquier repo.
Colección centralizada de **skills** (herramientas atómicas), **agents** (orquestadores autónomos),
**prompts**, **rules**, **hooks** y **MCP servers** para integrar con AI coding assistants
(Claude Code, Cursor, Codex) y pipelines de automatización.

---

## Conceptos Clave

| Concepto | Descripción |
|---|---|
| **Skill** | Herramienta atómica y reutilizable. Hace una sola cosa bien. Invocable via `/skill-name`. |
| **Agent** | Orquestador autónomo que combina skills para completar tareas complejas. |
| **Prompt** | Plantilla de prompt reutilizable para tareas específicas. Parametrizable. |
| **Rule** | Regla de comportamiento para AI models (`.cursorrules`, `CLAUDE.md`, etc.). |
| **Hook** | Automatización disparada por eventos del coding assistant (pre-commit, post-task, etc.). |
| **MCP Server** | Integración via Model Context Protocol — hace tools enterprise accesibles a cualquier modelo. |
| **Template** | Scaffolding para crear nuevos components siguiendo las convenciones del repo. |
| **Registry** | Índice machine-readable (`registry.json`) con metadata de todos los componentes. |
| **Context Layer** | Sistema de snapshots por capas para carga rápida de contexto (ver Fase 3). |

---

## Estructura de Carpetas (objetivo final)

```
tw-ai-toolkit/
├── AGENTS.md                    # Contexto global para AI models (L1 context)
├── PLAN.md                      # Este archivo
├── README.md                    # Overview del proyecto (humanos)
├── registry.json                # Índice machine-readable de todos los componentes (L2 context)
│
├── docs/
│   ├── onboarding.md            # Guia de inicio para nuevos usuarios
│   ├── integration-guide.md     # Como usar el toolkit desde otro repo
│   ├── contributing.md          # Como crear y contribuir nuevos componentes
│   └── compatibility-matrix.md  # Que componentes funcionan con que modelos/assistants
│
├── context/                     # Context Layers — sistema de memory checkpoints
│   ├── snapshot.md              # Snapshot auto-generado del estado del toolkit (L2)
│   ├── snapshots/               # Snapshots por componente (L3)
│   │   ├── skills.snapshot.md
│   │   ├── agents.snapshot.md
│   │   └── mcp.snapshot.md
│   └── CHECKPOINT.md            # Metadatos del ultimo snapshot (fecha, hash, version)
│
├── skills/                      # Herramientas atomicas
│   ├── _template/               # Template para crear nuevos skills
│   └── <skill-name>/
│       ├── skill.md             # Definicion del skill (prompt, params, ejemplos)
│       └── README.md            # Documentacion humana
│
├── agents/                      # Orquestadores autonomos
│   ├── _template/
│   └── <agent-name>/
│       ├── agent.md             # Definicion del agent (objetivo, skills usados, flujo)
│       └── README.md
│
├── prompts/                     # Plantillas de prompts reutilizables
│   ├── _template/
│   └── <prompt-name>/
│       ├── prompt.md            # Template con variables {{param}}
│       └── README.md
│
├── rules/                       # Reglas de comportamiento para AI models
│   ├── _template/
│   ├── claude/                  # Rules para Claude Code (CLAUDE.md fragments)
│   ├── cursor/                  # Rules para Cursor (.cursorrules)
│   └── codex/                  # Rules para Codex
│
├── hooks/                       # Automatizaciones por eventos
│   ├── _template/
│   └── <hook-name>/
│       ├── hook.md              # Definicion y configuracion del hook
│       └── README.md
│
├── mcp/                         # MCP Servers para integraciones enterprise
│   ├── _template/
│   └── <server-name>/
│       ├── server.md            # Definicion del MCP server
│       ├── config.json          # Schema de configuracion
│       └── README.md
│
├── config/                      # Configuracion y secrets management
│   ├── .env.example             # Variables de entorno requeridas
│   └── config.schema.json       # Schema de configuracion del toolkit
│
├── scripts/                     # Scripts de mantenimiento del toolkit
│   ├── sync-registry.sh         # Regenera registry.json desde los componentes
│   ├── sync-snapshots.sh        # Regenera context snapshots (L2/L3)
│   └── install.sh               # Script de instalacion en repos consumidores
│
└── tests/                       # Tests de skills y agents
    ├── _fixtures/
    └── <component-name>/
        └── test.md              # Casos de prueba del componente
```

---

## Fases de Trabajo

### Fase 0 — Fundamentos y Arquitectura
**Objetivo:** Definir las bases del proyecto antes de escribir codigo.

- [x] Crear `AGENTS.md` — contexto global L1 (manual, primer draft)
- [x] Crear `docs/onboarding.md` — guia de inicio para nuevos usuarios
- [x] Crear `docs/integration-guide.md` — como usar el toolkit desde otro repo
- [x] Crear `docs/contributing.md` — como crear nuevos componentes
- [x] Crear `docs/compatibility-matrix.md` — modelos soportados y limitaciones
- [x] Definir `config/config.schema.json` — schema de configuracion base
- [x] Crear `config/.env.example` — variables requeridas
- [x] Crear `registry.json` inicial (vacio, con schema definido)
- [x] Crear `config/registry.schema.json` — schema del registry
- [x] Crear `context/snapshot.md` — snapshot L2 inicial
- [x] Crear `context/CHECKPOINT.md` — metadatos de freshness del snapshot
- [x] Actualizar `README.md`

**Entregable:** Repo navegable y documentado. Cualquier dev puede entender el proyecto leyendo estos archivos.

---

### Fase 1 — Context Layer System (Memory Checkpoints)
**Objetivo:** Implementar el sistema de carga rapida de contexto para AI models.

El problema que resuelve: cada vez que un AI assistant abre el repo, debe explorar todos los archivos
para entender que hay disponible. Esto consume tokens y tiempo. El Context Layer System pre-computa
y almacena esta informacion en snapshots estructurados.

#### Arquitectura de capas:

```
L1 — AGENTS.md          Siempre cargado. Resumen ejecutivo: que es el toolkit,
                         que componentes existen (lista), como cargar mas contexto.
                         Costo: minimo. Formato: Markdown legible por humanos y modelos.

L2 — registry.json      Indice machine-readable. Metadata de todos los componentes:
     + snapshot.md       nombre, tipo, descripcion, params, dependencias, compatibilidad,
                         path, ultima actualizacion. El modelo lo consulta para saber
                         que existe sin leer cada archivo.
                         Costo: bajo. Se carga bajo demanda.

L3 — snapshots/          Contexto detallado por categoria de componente.
     *.snapshot.md       Solo se carga cuando el modelo necesita trabajar con
                         esa categoria especifica.
                         Costo: medio. Carga selectiva.

L4 — Archivo original    El modelo lee el archivo real solo cuando va a ejecutar
     del componente      o modificar el componente.
     (skill.md, etc.)    Costo: completo. Solo cuando es necesario.
```

- [x] Definir schema de `registry.json` — `config/registry.schema.json`
- [x] Crear `context/CHECKPOINT.md` — metadatos del snapshot (fecha, git hash, version del toolkit)
- [x] Crear `context/snapshot.md` — snapshot general L2 (auto-generado)
- [x] Definir formato de snapshots L3 por tipo de componente — `context/snapshots/*.snapshot.md`
- [x] Crear `scripts/sync-registry.sh` — escanea componentes y regenera `registry.json`
- [x] Crear `scripts/sync-snapshots.sh` — regenera snapshots L2/L3 y CHECKPOINT.md
- [x] Crear git hook `pre-commit` — auto-sync cuando se commitean cambios a componentes
- [x] Crear `scripts/install-git-hooks.sh` — instala el hook con un comando
- [x] Documentar en `AGENTS.md` como usar el Context Layer System

**Entregable:** Un modelo puede obtener contexto completo del toolkit con 2-3 lecturas en lugar de explorar decenas de archivos. Los snapshots se mantienen actualizados automaticamente.

---

### Fase 2 — Templates y Convenciones
**Objetivo:** Definir los contratos de cada tipo de componente y crear templates para nuevas contribuciones.

- [x] Definir schema/formato de `skill.md` — frontmatter + secciones obligatorias
- [x] Definir schema/formato de `agent.md` — frontmatter + flow + skills usados
- [x] Definir schema/formato de `prompt.md` — frontmatter + template con {{variables}}
- [x] Definir schema/formato de `rule.md` — frontmatter + target + content por modelo
- [x] Definir schema/formato de `hook.md` — frontmatter + event + action + config
- [x] Definir schema/formato de `server.md` — MCP: frontmatter + tools + auth + setup
- [x] Crear `skills/_template/` con skill completamente documentado
- [x] Crear `agents/_template/` con agent completamente documentado
- [x] Crear `prompts/_template/` con prompt de ejemplo
- [x] Crear `rules/_template/` con rule de ejemplo
- [x] Crear `hooks/_template/` con hook de ejemplo
- [x] Crear `mcp/_template/` con MCP server de ejemplo
- [x] Crear `tests/_template/` con test de ejemplo
- [x] `docs/contributing.md` — guia completa ya existente desde Fase 0

**Entregable:** Cualquier dev puede crear un nuevo componente sin consultar a nadie, siguiendo el template.

---

### Fase 3 — Primer Set de Componentes (Core)
**Objetivo:** Poblar el toolkit con componentes fundamentales de alto valor.

#### Skills core:
- [x] `sync-context` — regenera el Context Layer System (registry + snapshots)
- [x] `lint-component` — valida que un componente sigue las convenciones del toolkit
- [x] `install-toolkit` — instala el toolkit en un repo consumidor

#### Agents core:
- [x] `onboard-repo` — analiza un repo nuevo y genera configuracion inicial del toolkit
- [x] `scaffold-component` — genera un nuevo componente desde un template dado el tipo y nombre

#### Rules core:
- [x] `rules/claude-base/` — reglas base para Claude Code + fragment.md listo para copiar
- [x] `rules/cursor-base/` — reglas base para Cursor + fragment.md listo para copiar

**Entregable:** Toolkit funcional con componentes core usables desde otros repos.

---

### Fase 4 — Sistema de Integracion (Consumer Repos)
**Objetivo:** Hacer el toolkit accesible y mantenible desde repos externos.

#### Metodos de integracion (a evaluar y documentar):

```
Opcion A — Git Submodule
  Ventaja: version exacta pinada, updates controlados
  Desventaja: requiere conocimiento de submodules

Opcion B — Git Subtree
  Ventaja: mas simple que submodule, historia integrada
  Desventaja: updates mas manuales

Opcion C — Script de instalacion (curl/wget)
  Ventaja: el mas simple para el usuario final
  Desventaja: no hay pinning automatico de version

Opcion D — npm/pip package (si aplica)
  Ventaja: ecosystem de package management conocido
  Desventaja: overhead de publicacion

Recomendacion: soportar A y C como minimo.
```

- [x] Crear `scripts/install.sh` — instala el toolkit en un repo (interactivo, curl-able)
- [x] Crear `scripts/update.sh` — actualiza con deteccion de breaking changes y confirmacion
- [x] Definir estrategia de versionado — `docs/versioning.md` (semver, lifecycle, branching)
- [x] Crear `CHANGELOG.md` — formato Keep a Changelog, requerido por politica de deprecacion
- [x] Documentar pinning de versiones — ya en `docs/integration-guide.md` (Fase 0)
- [x] Fragment de `CLAUDE.md` — `rules/claude-base/fragment.md` (Fase 3)
- [x] Fragment de `.cursorrules` — `rules/cursor-base/fragment.md` (Fase 3)
- [x] Override strategy — ya en `docs/integration-guide.md` seccion "Local Overrides" (Fase 0)

**Entregable:** Guia completa para instalar, usar y actualizar el toolkit desde cualquier repo.

---

### Fase 5 — Testing Framework
**Objetivo:** Garantizar que los componentes funcionan correctamente.

- [x] Definir estrategia de testing — `docs/testing.md` (2 capas: automatizada + manual)
- [x] Crear `scripts/validate.sh` — CI-runnable: schema, referencias, registry drift, freshness
- [x] Crear `tests/_fixtures/` — `valid-skill.md` + `invalid-skill.md`
- [x] Crear tests para componentes core — sync-context, lint-component, scaffold-component, install-toolkit
- [x] Template de test ya creado en Fase 2 — `tests/_template/test.md`
- [x] Definir CI pipeline — `.github/workflows/ci.yml` (GitHub Actions, bloquea PRs en FAIL)
- [x] Agregar badge de estado al README

**Entregable:** Cada componente tiene tests. El CI bloquea PRs que rompan componentes existentes.

---

### Fase 6 — MCP Servers (Integraciones Enterprise)
**Objetivo:** Exponer integraciones enterprise via Model Context Protocol.

- [x] Investigar MCP servers prioritarios — `tw-github` y `tw-jira` como primeros
- [x] Crear `docs/mcp-guide.md` — guia completa: que es MCP, setup, seguridad, troubleshooting
- [x] Crear `mcp/tw-github/` — 17 tools, auth PAT, setup Claude Code + Cursor
- [x] Crear `mcp/tw-jira/` — 14 tools, auth API token, JQL, sprints
- [x] Crear `config/mcp-server.schema.json` — schema para config.json de cada MCP server
- [x] MCP servers agregados al Context Layer System — registry + mcp.snapshot.md

**Entregable:** Al menos un MCP server enterprise funcional e integrado en el toolkit.

---

### Fase 7 — Secrets y Config Management
**Objetivo:** Patron claro y seguro para manejo de credenciales y configuracion.

- [x] Definir jerarquia — env vars → .ai/config.json → config/defaults.json
- [x] Crear `config/defaults.json` — capa de defaults del toolkit
- [x] Ampliar `config/config.schema.json` — seccion `secrets` con 5 providers
- [x] Crear `docs/secrets-guide.md` — .env, CI/CD, AWS, Vault, GCP, rotacion, checklist
- [x] Crear `scripts/validate-config.sh` — valida config.json + env vars de MCP servers activos
- [x] Actualizar `skills/lint-component` — validacion de config.json de MCP servers

**Entregable:** Ningun secreto en el repo. Patron reproducible y seguro para configuracion.

---

### Fase 8 — Compatibility Matrix y Multi-Model Support
**Objetivo:** Garantizar que los componentes funcionan con todos los AI assistants soportados.

- [x] Definir features por asistente — tabla completa en `docs/compatibility-matrix.md`
- [x] Campo `compatible_with` en schema desde Fase 0 — declarado en todos los componentes
- [x] Actualizar `docs/compatibility-matrix.md` — componentes reales, workarounds, Context Layer compat
- [x] Documentar workarounds por asistente — Cursor (Composer, MCP), Codex (prompts manuales, reglas)
- [x] Agregar snapshots por asistente — `context/snapshots/cursor.snapshot.md` (7 items) + `context/snapshots/codex.snapshot.md`
- [x] Actualizar `AGENTS.md` — referencias a L3+ snapshots por asistente

**Entregable:** El usuario sabe exactamente que puede usar con su AI assistant sin prueba y error.

---

## Decisiones Resueltas

| # | Decision | Eleccion |
|---|---|---|
| 1 | Carpeta en repos consumidores | `.ai/` — oculta, corta, neutral al modelo |
| 2 | Idioma de los componentes | Ingles en todo (instrucciones, docs, nombres) |
| 3 | Namespace de skills | Prefijo `tw-` — ej: `/tw-lint`, `/tw-sync-context` |
| 4 | Estrategia de updates | Opcion B por defecto (`/tw-update`), Opcion C (Dependabot) opcional |
| 5 | Politica de deprecacion | Ciclo de vida: `stable → deprecated (2 minor versions) → removed (solo en major)` |

### Reglas de deprecacion (Decision 5)

```
stable      Disponible y soportado              indefinido
deprecated  Funciona pero avisa al usuario      minimo 2 minor versions
removed     Eliminado — solo en major release
```

- Nunca se elimina un componente en minor o patch release
- Todo componente a eliminar pasa por `deprecated` al menos 2 versiones antes
- `registry.json` incluye campos `deprecated_since` y `removed_in`
- `CHANGELOG.md` lista cada deprecacion y su reemplazo

---

## Metricas de Exito

- Un dev nuevo puede instalar y usar el toolkit en menos de 10 minutos (Fase 0 + 4)
- Un AI model puede obtener contexto completo del toolkit en menos de 3 lecturas (Fase 1)
- Crear un nuevo componente toma menos de 15 minutos siguiendo el template (Fase 2)
- El CI bloquea componentes malformados antes de llegar a main (Fase 5)

---

## Orden de Ejecucion Recomendado

```
Fase 0 → Fase 1 → Fase 2 → Fase 3 → Fase 4 → Fase 7 → Fase 5 → Fase 6 → Fase 8
```

Las primeras 4 fases son bloqueantes entre si. A partir de Fase 5, se puede paralelizar.

---

*Este plan es un documento vivo. Se actualiza al inicio de cada fase.*
