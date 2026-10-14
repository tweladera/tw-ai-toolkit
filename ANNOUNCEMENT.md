# tw-ai-toolkit — Announcement / Anuncio

---

## English

**tw-ai-toolkit is now available**

We've released a centralized toolkit of AI components for engineering teams — skills, agents, rules, and MCP server integrations designed to work with Claude Code and Cursor out of the box.

**What it includes (v0.5.0 — 44 components):**

- **29 skills** covering the full quality lifecycle: spec generation, unit/integration/E2E/performance/security testing, compliance audits, living documentation, and more
- **5 agents** for autonomous workflows: Day 1 client bootstrap, GO/NO-GO release readiness, autonomous quality sprints
- **6 behavioral rules** that shape how the AI assistant works: spec-first, security-first, performance budget, consultant mindset
- **6 MCP server integrations**: GitHub, GitLab, Jira, Confluence, SonarQube, Azure DevOps

**Built for consultants and QA / SDET engineers.** Every component auto-detects your stack (TypeScript, Python, Java, Go, .NET), CI platform (GitHub Actions, GitLab CI, Azure DevOps, Jenkins), and cloud provider — no hardcoded assumptions. Works on any client, any industry.

**Get started in under 5 minutes:**

The toolkit installs **locally only** — it is never committed or pushed to your repo.

```bash
# Step 1 — clone the toolkit once (anywhere on your machine)
git clone https://github.com/tweladera/tw-ai-toolkit.git ~/tw-ai-toolkit

# Step 2 — install into your project (run from your project root)
python3 ~/tw-ai-toolkit/scripts/install.py --local ~/tw-ai-toolkit
python3 .ai/toolkit/scripts/install.py --link-all
python3 .ai/toolkit/scripts/install.py --verify
```

Everything gets added to `.gitignore` automatically — your remote repo stays clean.

Then open Claude Code and type:
```
Load .ai/AGENTS.md
```

Repository: https://github.com/tweladera/tw-ai-toolkit
Full component list: see `AGENTS.md` or `QUICKSTART.md`

---

## Espanol

**tw-ai-toolkit ya esta disponible**

Lanzamos un toolkit centralizado de componentes de IA para equipos de ingenieria — skills, agents, rules e integraciones MCP disenados para funcionar con Claude Code y Cursor sin configuracion adicional.

**Que incluye (v0.5.0 — 44 componentes):**

- **29 skills** que cubren el ciclo completo de calidad: generacion de specs, testing unitario/integracion/E2E/performance/seguridad, auditorias de compliance, living documentation y mas
- **5 agents** para flujos autonomos: bootstrap de cliente en el Dia 1, decision GO/NO-GO para releases, quality sprints autonomos
- **6 reglas de comportamiento** que moldean como trabaja el asistente de IA: spec-first, security-first, presupuesto de performance, mindset consultor
- **6 integraciones MCP**: GitHub, GitLab, Jira, Confluence, SonarQube, Azure DevOps

**Disenado para consultores e ingenieros QA / SDET.** Cada componente detecta automaticamente tu stack (TypeScript, Python, Java, Go, .NET), plataforma CI (GitHub Actions, GitLab CI, Azure DevOps, Jenkins) y proveedor cloud — sin suposiciones hardcodeadas. Funciona con cualquier cliente, cualquier industria.

**Primeros pasos en menos de 5 minutos:**

El toolkit se instala **solo en local** — nunca se commitea ni se sube al repo.

```bash
# Paso 1 — clonar el toolkit una vez (en cualquier lugar de tu maquina)
git clone https://github.com/tweladera/tw-ai-toolkit.git ~/tw-ai-toolkit

# Paso 2 — instalar en tu proyecto (ejecutar desde la raiz del proyecto)
python3 ~/tw-ai-toolkit/scripts/install.py --local ~/tw-ai-toolkit
python3 .ai/toolkit/scripts/install.py --link-all
python3 .ai/toolkit/scripts/install.py --verify
```

Todo se agrega automaticamente al `.gitignore` — tu repo remoto queda limpio.

Luego abre Claude Code y escribe:
```
Load .ai/AGENTS.md
```

Repositorio: https://github.com/tweladera/tw-ai-toolkit
Lista completa de componentes: ver `AGENTS.md` o `QUICKSTART.md`
