# CONTRIBUTING — Guía para extender y mantener tw-ai-toolkit

Este documento explica cómo agregar nuevos componentes al toolkit, cómo validarlos,
qué archivos nunca deben modificarse manualmente y qué información es relevante para
cualquier persona que trabaje en este repo.

---

## IMPORTANTE: Reglas de oro

> Leer esto antes de tocar cualquier archivo.

### Archivos que NUNCA se deben editar manualmente

| Archivo / directorio | Por qué |
|---|---|
| `registry.json` | Auto-generado por `sync-registry.sh`. Editar a mano causa inconsistencias. |
| `context/snapshot.md` | Auto-generado por `sync-snapshots.sh`. |
| `context/snapshots/` | Todo el directorio es auto-generado. |
| `context/CHECKPOINT.md` | Auto-generado. Refleja el estado de los snapshots. |

**Si modificas cualquiera de estos archivos a mano, el CI fallará en el próximo push.**

### Archivos que sí se pueden y deben editar

| Archivo / directorio | Cuándo editarlo |
|---|---|
| `skills/<nombre>/skill.md` | Al crear o modificar un skill |
| `agents/<nombre>/agent.md` | Al crear o modificar un agent |
| `prompts/<nombre>/prompt.md` | Al crear o modificar un prompt |
| `rules/<nombre>/rule.md` | Al crear o modificar una rule |
| `hooks/<nombre>/hook.md` | Al crear o modificar un hook |
| `mcp/<nombre>/server.md` | Al crear o modificar un MCP server |
| `docs/` | Al mejorar documentación |
| `scripts/` | Solo si entiendes el impacto en CI y en repos consumidores |

---

## Cómo agregar un nuevo componente

### Paso 1 — Usa el agent de scaffolding (recomendado)

Desde Claude Code en este repo:

```
/tw-scaffold-component type=skill name=mi-nuevo-skill
```

El agent crea la estructura de carpetas y archivos desde la plantilla correcta.

### Paso 2 — Si prefieres hacerlo manual, copia la plantilla

```bash
# Reemplaza <tipo> con: skills, agents, prompts, rules, hooks, o mcp
cp -r <tipo>/_template/ <tipo>/<nombre-del-componente>/
```

Las plantillas viven en `<tipo>/_template/`. Cada campo marcado con `[REQUIRED]`
debe ser completado antes de que el linter lo apruebe.

### Paso 3 — Completa el archivo de definición

Cada tipo tiene su propio archivo de definición:

| Tipo | Archivo | Sección clave |
|---|---|---|
| Skill | `skill.md` | `## Instructions` — las instrucciones reales que sigue el AI |
| Agent | `agent.md` | `## Flow` — pasos del flujo autónomo |
| Prompt | `prompt.md` | `## Template` — el prompt con variables `{{como_esta}}` |
| Rule | `rule.md` | `## Rule Content` — la regla de comportamiento |
| Hook | `hook.md` | `## Action` — el comando que se ejecuta |
| MCP Server | `server.md` | `## Tools Exposed` — lista de herramientas que expone |

Para ver el schema completo de cada tipo, revisa `docs/contributing.md`.

### Paso 4 — Valida el componente

```bash
/tw-lint-component <tipo>/<nombre>
```

O directamente con el script:

```bash
bash scripts/validate.sh
```

El linter verifica:
- Todos los campos `[REQUIRED]` están completos
- El nombre del directorio coincide con el campo `name` del frontmatter
- No hay texto placeholder sin reemplazar
- Las secciones requeridas están presentes
- Las referencias a otros skills existen en el registry

**No hagas commit si el linter reporta errores.**

### Paso 5 — Sincroniza el registry y los snapshots

```bash
bash scripts/sync-registry.sh
bash scripts/sync-snapshots.sh
```

Esto actualiza `registry.json` y todos los archivos en `context/` para reflejar
el nuevo componente. Estos archivos generados **deben incluirse en el mismo commit**
que el componente.

Si tienes el git hook instalado, esto ocurre automáticamente al hacer commit:

```bash
bash scripts/install-git-hooks.sh
```

### Paso 6 — Commit y PR

```bash
git add <tipo>/<nombre>/ registry.json context/
git commit -m "feat(<tipo>): add <nombre>"
```

El CI validará todo automáticamente antes de mergear.

---

## Cómo deprecar un componente

Nunca elimines un componente directamente. Sigue el ciclo de vida:

1. Cambia el campo `status` a `deprecated` en el archivo de definición
2. Agrega `deprecated_since: vX.Y.Z` (versión actual)
3. Agrega `removed_in: vX.0.0` (próxima versión mayor)
4. Agrega `replacement: nombre-del-nuevo-componente` si aplica
5. Corre `sync-registry.sh` y `sync-snapshots.sh`
6. Documenta el cambio en `CHANGELOG.md`

El componente seguirá funcionando pero advertirá al usuario cuando se invoque.
**Los componentes solo se eliminan en versiones mayores (v1.0.0 → v2.0.0).**

---

## Convenciones de nomenclatura

```
Formato:         kebab-case
Idioma:          Inglés — nombres, descripciones, instrucciones
Prefijo toolkit: tw- (se agrega en invocación, NO en el nombre de carpeta)

Carpeta:   skills/run-tests/
Invocado:  /tw-run-tests
```

---

## Para usuarios del toolkit en repos consumidores

Si usas este toolkit instalado en tu repo (vía `--local-only`), ten en cuenta:

### NO hagas esto en tu repo

```
❌ Editar archivos dentro de .ai/toolkit/
❌ Modificar .ai/toolkit/registry.json
❌ Borrar archivos de .ai/toolkit/context/
```

Modificar `.ai/toolkit/` directamente significa que tu copia del toolkit diverge
del repo oficial. La próxima vez que actualices con `git pull`, perderás tus cambios.

### SÍ puedes hacer esto

```
✅ Agregar skills locales en .ai/skills/<nombre>/skill.md
✅ Agregar agents locales en .ai/agents/<nombre>/agent.md
✅ Modificar .ai/config.json para tu configuración local
✅ Crear tu propio CLAUDE.md con instrucciones adicionales
```

Los componentes locales en `.ai/skills/` y `.ai/agents/` tienen prioridad sobre
los del toolkit y no usan el prefijo `/tw-`.

### Para actualizar el toolkit a la última versión

```bash
cd .ai/toolkit && git pull origin main
```

---

## Estructura del repo

```
tw-ai-toolkit/
├── skills/            # Skills atómicos (/tw-<nombre>)
│   ├── _template/     # Plantilla base para nuevos skills
│   └── <nombre>/
│       ├── skill.md   # Definición principal (YAML frontmatter + markdown)
│       └── README.md  # Descripción legible para humanos
├── agents/            # Agents orquestadores (/tw-<nombre>)
├── prompts/           # Plantillas de prompts reutilizables
├── rules/             # Reglas de comportamiento para AI models
├── hooks/             # Automatizaciones por eventos
├── mcp/               # Configuraciones de MCP servers
├── context/           # AUTO-GENERADO — no editar manualmente
│   ├── snapshot.md
│   ├── CHECKPOINT.md
│   └── snapshots/
├── config/            # Schemas JSON y configuración base
├── docs/              # Documentación técnica detallada
├── scripts/           # Scripts de sync, install, validate y update
├── tests/             # Casos de prueba por componente
├── registry.json      # AUTO-GENERADO — no editar manualmente
├── AGENTS.md          # Contexto L1 para AI models
├── QUICKSTART.md      # Guía de instalación y uso
└── CONTRIBUTING.md    # Este archivo
```

---

## Recursos relacionados

| Documento | Contenido |
|---|---|
| `QUICKSTART.md` | Instalación y uso del toolkit en repos consumidores |
| `docs/contributing.md` | Schema detallado de cada tipo de componente |
| `docs/versioning.md` | Política de versiones y ciclo de vida |
| `docs/compatibility-matrix.md` | Qué funciona en Claude Code vs Cursor vs Codex |
| `docs/mcp-guide.md` | Guía completa de configuración de MCP servers |
| `docs/secrets-guide.md` | Manejo de credenciales y variables de entorno |
