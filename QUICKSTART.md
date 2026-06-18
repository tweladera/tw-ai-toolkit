# tw-ai-toolkit — Quickstart

Guía para instalar, configurar y usar el toolkit en cualquier repo de desarrollo.

---

## ¿Qué es tw-ai-toolkit?

Un conjunto centralizado de skills, agents, rules y MCP servers que amplían las capacidades
de tu asistente AI (Claude Code, Cursor) dentro de tus proyectos. El toolkit vive en su
propio repositorio y se instala localmente en cada repo donde quieras usarlo — sin formar
parte de tu código.

---

## Prerequisitos

- Git instalado
- Claude Code (recomendado) o Cursor
- Acceso al repo del toolkit (actualmente en `https://github.com/tweladera/tw-ai-toolkit`)

---

## Instalación

### Opción A — Desde GitHub (remoto)

Párate en la raíz del repo donde quieres usar el toolkit y ejecuta:

```bash
curl -fsSL "https://raw.githubusercontent.com/tweladera/tw-ai-toolkit/main/scripts/install.sh" \
  -o /tmp/tw-install.sh && bash /tmp/tw-install.sh --local-only
```

### Opción B — Desde copia local (recomendada si tienes el repo clonado)

```bash
bash /ruta/a/tw-ai-toolkit/scripts/install.sh --local-only
```

Ejemplo real:
```bash
bash /Users/evansladera/workspace-tw/tw-qa/tw-ai-toolkit/scripts/install.sh --local-only
```

### ¿Qué hace la instalación?

1. Clona el toolkit en `.ai/toolkit/` dentro de tu repo
2. Crea `.ai/config.json` con la configuración local
3. Crea `.ai/AGENTS.md` con el contexto del toolkit para el AI
4. Crea `CLAUDE.md` en la raíz con las instrucciones de carga para Claude Code
5. Agrega todos estos archivos a `.git/info/exclude` — **nunca se commitean, nunca van a GitHub**

---

## Verificar la instalación

Después de instalar, abre Claude Code en ese repo y escribe:

```
¿Qué componentes del toolkit están disponibles?
```

Claude Code leerá automáticamente el `CLAUDE.md` y cargará el contexto del toolkit.

---

## Componentes disponibles

### Skills — Herramientas atómicas (invocación: `/tw-<nombre>`)

Los skills son acciones puntuales que le pides al AI que ejecute.

| Skill | Invocación | Para qué usarlo | Cuándo usarlo |
|---|---|---|---|
| **sync-context** | `/tw-sync-context` | Regenera el registry y los snapshots de contexto del toolkit | Después de modificar o agregar componentes al toolkit |
| **lint-component** | `/tw-lint-component <path>` | Valida que un componente sigue el schema y las convenciones del toolkit | Antes de hacer commit de un componente nuevo o modificado |
| **install-toolkit** | `/tw-install-toolkit` | Guía la instalación del toolkit en un repo consumidor desde el AI | Cuando quieres instalar el toolkit sin salir de Claude Code |

**Ejemplos de uso:**

```
/tw-sync-context
/tw-lint-component skills/mi-nuevo-skill
```

---

### Agents — Orquestadores autónomos (invocación: `/tw-<nombre>`)

Los agents ejecutan flujos de múltiples pasos de forma autónoma.

| Agent | Invocación | Para qué usarlo | Cuándo usarlo |
|---|---|---|---|
| **onboard-repo** | `/tw-onboard-repo` | Analiza tu repo y configura el toolkit adaptado a tu stack | Al instalar el toolkit por primera vez en un proyecto nuevo |
| **scaffold-component** | `/tw-scaffold-component` | Crea un nuevo componente del toolkit desde la plantilla correcta | Cuando quieres agregar un skill, agent, rule o prompt al toolkit |

**Ejemplos de uso:**

```
/tw-onboard-repo
/tw-scaffold-component type=skill name=run-tests
```

---

### Rules — Reglas de comportamiento para el AI

Las rules se cargan automáticamente vía `CLAUDE.md` y definen cómo debe comportarse
el AI al trabajar en repos que usan el toolkit. No se invocan manualmente.

| Rule | Para quién | Qué hace |
|---|---|---|
| **claude-base** | Claude Code | Define cómo cargar el contexto del toolkit, qué archivos no editar manualmente y cómo invocar componentes |
| **cursor-base** | Cursor | Equivalente a claude-base pero adaptado al flujo de Cursor |

---

### MCP Servers — Integraciones enterprise

Los MCP servers exponen herramientas externas directamente al AI. Se configuran una vez
en Claude Code y quedan disponibles en todas las sesiones.

| Servidor | Para qué usarlo | Cuándo configurarlo |
|---|---|---|
| **tw-github** | Permite al AI leer PRs, issues, commits y repos de GitHub directamente | Cuando trabajas con GitHub y quieres que el AI tenga contexto de PRs e issues sin copiar/pegar |
| **tw-jira** | Permite al AI consultar y actualizar tickets de Jira | Cuando tu equipo usa Jira y quieres que el AI relacione código con tickets automáticamente |

Para configurar un MCP server, lee su guía en:
```
.ai/toolkit/mcp/tw-github/server.md
.ai/toolkit/mcp/tw-jira/server.md
```

---

## Flujo de trabajo típico

```
1. Abres Claude Code en tu repo
2. Claude Code carga CLAUDE.md automáticamente
3. Trabajas en tu código normalmente
4. Usas /tw-<skill> cuando necesitas una acción específica del toolkit
5. git add / commit / push — solo tu código, el toolkit no aparece
```

---

## Actualizar el toolkit

```bash
cd .ai/toolkit && git pull origin main
```

---

## Desinstalar / limpiar

```bash
rm -rf .ai/
rm -f CLAUDE.md
rm -f .env.toolkit.example
```

Los archivos ya estaban en `.git/info/exclude`, así que git nunca los rastreó — no hay
nada que revertir en el historial.

---

## Reinstalar desde cero

Después de limpiar, simplemente vuelve a ejecutar el install:

```bash
bash /ruta/a/tw-ai-toolkit/scripts/install.sh --local-only
```

---

## Estructura de archivos tras la instalación

```
tu-repo/
├── .ai/
│   ├── toolkit/          # toolkit clonado (gitignored)
│   │   ├── AGENTS.md
│   │   ├── registry.json
│   │   ├── skills/
│   │   ├── agents/
│   │   ├── rules/
│   │   └── mcp/
│   ├── AGENTS.md         # pointer local al toolkit
│   └── config.json       # configuración local
├── CLAUDE.md             # instrucciones de carga para Claude Code (gitignored)
└── tu-código/
```

---

## Referencia rápida de comandos

| Qué quiero hacer | Comando |
|---|---|
| Instalar el toolkit | `bash /ruta/tw-ai-toolkit/scripts/install.sh --local-only` |
| Ver componentes disponibles | Pregunta al AI: "¿Qué componentes del toolkit están disponibles?" |
| Onboardear un repo nuevo | `/tw-onboard-repo` en Claude Code |
| Sincronizar contexto | `/tw-sync-context` en Claude Code |
| Validar un componente | `/tw-lint-component <path>` en Claude Code |
| Actualizar el toolkit | `cd .ai/toolkit && git pull origin main` |
| Desinstalar | `rm -rf .ai/ CLAUDE.md .env.toolkit.example` |
