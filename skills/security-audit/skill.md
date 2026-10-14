---
name: security-audit
description: Runs a multi-layer security audit combining static analysis (OWASP Top 10 code patterns), dependency vulnerability scanning (npm audit, pip-audit, OWASP Dependency Check), and optional DAST with OWASP ZAP. Stack-agnostic and CI-ready.
status: stable
version_added: v0.5.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: mode
    type: string
    required: false
    default: "scan"
    description: "'scan' for static + dependency analysis (no running app needed), 'dast' for dynamic scan against a running instance, 'full' for both."
  - name: target
    type: string
    required: false
    default: ""
    description: "For 'dast' mode: base URL of the running application (e.g. http://localhost:3000). Required only for dast/full."
  - name: stack
    type: string
    required: false
    default: ""
    description: "Tech stack: 'typescript', 'python', 'java', 'dotnet', 'go', 'ruby'. Auto-detected."
  - name: owasp_categories
    type: string
    required: false
    default: "all"
    description: "Comma-separated OWASP Top 10 categories to focus on (e.g. 'A01,A02,A03'). Default: all."
  - name: severity_threshold
    type: string
    required: false
    default: "medium"
    description: "Minimum severity to report: 'critical', 'high', 'medium', 'low'. Default: medium."
tags:
  - security
  - owasp
  - vulnerability
  - dependency-scan
  - dast
  - sast
  - compliance
  - qa
invocation: tw-security-audit
---

# security-audit

## Description

Security testing is the most consistently missing layer in QA suites. Most governance
reports focus on coverage and mutation scores — none of that matters if the application
has an SQL injection vulnerability or ships dependencies with known CVEs.

`security-audit` brings the security layer into the same AI-assisted workflow as the
rest of the toolkit. It does not replace a dedicated security engineer, but it provides
the **baseline security posture** that every client engagement should establish before
any other conversation about quality happens.

**Three complementary layers:**
- **SAST (Static)**: Code pattern analysis for OWASP Top 10 vulnerabilities — injections,
  broken auth, exposed secrets, insecure deserialization, misconfigured security headers
- **SCA (Dependencies)**: Scans `package.json`, `requirements.txt`, `pom.xml`, `build.gradle`,
  `go.mod`, `Gemfile` for known CVEs using native tooling per ecosystem
- **DAST (Dynamic)**: OWASP ZAP spider + active scan against a running application — finds
  vulnerabilities that only manifest at runtime (reflected XSS, header injection, open redirects)

**Why this matters for a consultant:** Every enterprise client has a security team that
will eventually ask "do you have a security scan?" Having this skill means the answer on
day 3, not day 90.

## When to Use

- Day 1 assessment of a new client project — establish the security baseline
- Before any release with external-facing changes
- After adding new dependencies — dependency scanning as a gate
- When a client mentions regulatory requirements (PCI-DSS, HIPAA, SOC2) — security scanning
  is a prerequisite for all of them

Triggers: "security scan", "check for vulnerabilities", "OWASP audit", "are our dependencies
safe", "security baseline", "CVE scan".

## Instructions

### Step 1 — Auto-Detect Stack and Entry Points

```bash
# Detect package managers / build files
ls package.json requirements.txt Pipfile pom.xml build.gradle go.mod Gemfile \
   *.csproj 2>/dev/null | head -10

# Detect main application entry points
find . -name "main.ts" -o -name "app.py" -o -name "Application.java" \
       -o -name "main.go" -o -name "Program.cs" 2>/dev/null | head -5

# Detect framework
rg "@nestjs|express|fastify" package.json 2>/dev/null && echo "nodejs"
rg "django|flask|fastapi" requirements.txt 2>/dev/null && echo "python"
rg "spring-boot" pom.xml build.gradle 2>/dev/null && echo "java"
```

### Step 2 — SAST: OWASP Top 10 Code Pattern Scan

Scan for the following vulnerability patterns across the codebase:

#### A01:2021 — Broken Access Control
```bash
# Missing authorization decorators / guards
rg "@Get\(|@Post\(|@Put\(|@Delete\(" src/ --type ts | \
  rg -v "@UseGuards|@Roles|@Public" | head -20

# Direct object reference without authorization check
rg "findById\(req\.params|findOne\(id\)" src/ --type ts | head -10
```

#### A02:2021 — Cryptographic Failures
```bash
# Weak hashing algorithms
rg "md5|sha1|createHash\(['\"]md5|createHash\(['\"]sha1" src/ -i | head -10

# HTTP (not HTTPS) hardcoded URLs
rg "http://" src/ --type ts --type py --type java | grep -v "localhost\|127\.0\.0\.1\|test\|spec" | head -10

# Secrets in code
rg "password\s*=\s*['\"][^'\"]+['\"]|api_key\s*=\s*['\"]|secret\s*=\s*['\"]" \
  src/ -i | grep -v "test\|spec\|example\|placeholder" | head -10
```

#### A03:2021 — Injection
```bash
# SQL injection risk — string concatenation in queries
rg "query\(.*\+|execute\(.*\+|raw\(.*\+" src/ --type ts --type py --type java | head -10

# Command injection risk
rg "exec\(|execSync\(|subprocess\.call\|os\.system\(" src/ | head -10

# NoSQL injection — unvalidated input in MongoDB queries
rg "\.find\(\{.*req\.|\.findOne\(\{.*req\." src/ --type ts | head -10
```

#### A05:2021 — Security Misconfiguration
```bash
# CORS wildcard
rg "origin.*\*|cors\(\)" src/ --type ts | head -10

# Debug mode in production configs
rg "DEBUG.*=.*true|debug.*=.*True" src/ config/ | grep -v test | head -10

# Stack traces exposed in error handlers
rg "stack.*res\.json|error\.stack.*send" src/ --type ts | head -10
```

#### A07:2021 — Identification and Authentication Failures
```bash
# JWT without expiration
rg "jwt\.sign\(" src/ --type ts | head -10
# Look for missing expiresIn option

# Password stored in plaintext (no bcrypt/argon2)
rg "password.*save\|user\.password.*=.*req" src/ | grep -v "hash\|bcrypt\|argon" | head -10

# Missing rate limiting on auth endpoints
rg "@Post.*login|@Post.*auth|@Post.*signin" src/ --type ts | head -10
```

#### A09:2021 — Security Logging and Monitoring Failures
```bash
# Missing audit logs for sensitive operations
rg "delete.*Order\|cancelOrder\|refundOrder\|deleteUser" src/ --type ts | \
  rg -v "log\|audit\|track" | head -10
```

### Step 3 — SCA: Dependency Vulnerability Scan

**Node.js:**
```bash
npm audit --json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
vulns = data.get('vulnerabilities', {})
for name, info in vulns.items():
    severity = info.get('severity', 'unknown')
    via = info.get('via', [])
    print(f'{severity.upper()}: {name} — via: {via}')
" | sort
```

**Python:**
```bash
# pip-audit (preferred)
pip-audit --format json 2>/dev/null || \
# safety as fallback
safety check --json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for vuln in data:
    print(f'{vuln[\"severity\"].upper()}: {vuln[\"package\"]} {vuln[\"installed_version\"]} — CVE: {vuln.get(\"cve\", \"N/A\")}')
"
```

**Java (Maven):**
```bash
mvn org.owasp:dependency-check-maven:check -DfailBuildOnCVSS=7 \
  -Dformat=JSON -DoutputDirectory=target/security 2>/dev/null
```

**Java (Gradle):**
```bash
./gradlew dependencyCheckAnalyze 2>/dev/null
```

**Go:**
```bash
govulncheck ./... 2>/dev/null || go list -json -m all | \
  docker run --rm -i golang:1.21 govulncheck -json
```

**.NET:**
```bash
dotnet list package --vulnerable --include-transitive 2>/dev/null
```

### Step 4 — DAST: OWASP ZAP Scan (mode=dast or mode=full)

```bash
# Baseline scan (passive + basic active) — safe for all environments
docker run --rm -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
  -t {{target}} \
  -J zap-report.json \
  -r zap-report.html \
  -l WARN

# Full scan — only in isolated environments, not production
# docker run --rm -t ghcr.io/zaproxy/zaproxy:stable zap-full-scan.py \
#   -t {{target}} -J zap-full-report.json
```

Parse ZAP output:
```bash
python3 -c "
import json
with open('zap-report.json') as f:
    data = json.load(f)
for alert in data.get('site', [{}])[0].get('alerts', []):
    risk = alert['riskdesc']
    name = alert['alert']
    count = alert['count']
    print(f'[{risk}] {name} ({count} instances)')
" | sort
```

### Step 5 — Generate Security Audit Report

```markdown
# Security Audit Report

**Project:** [auto-detected]
**Date:** YYYY-MM-DD
**Stack:** TypeScript / NestJS (auto-detected)
**Mode:** scan (SAST + SCA)
**Generated by:** /tw-security-audit | v0.5.0

---

## Executive Summary

| Layer | Issues Found | Critical | High | Medium | Low |
|---|---|---|---|---|---|
| SAST (code patterns) | 8 | 1 | 2 | 3 | 2 |
| SCA (dependencies) | 5 | 0 | 3 | 2 | 0 |
| DAST (runtime) | — | — | — | — | — |

**Immediate action required:** 1 critical, 5 high severity issues.

---

## Critical — Fix Before Next Deployment

### [SAST] A03 — SQL Injection Risk
- **File:** `src/orders/order.repository.ts:47`
- **Pattern:** String concatenation in raw query
  ```typescript
  // VULNERABLE
  this.db.query(`SELECT * FROM orders WHERE user_id = '${userId}'`);
  // SAFE
  this.db.query('SELECT * FROM orders WHERE user_id = $1', [userId]);
  ```
- **OWASP:** A03:2021 — Injection
- **Fix:** Use parameterized queries — never interpolate user input into SQL

---

## High Severity

### [SCA] lodash 4.17.15 — Prototype Pollution
- **CVE:** CVE-2021-23337
- **CVSS:** 7.2 (High)
- **Fix:** Upgrade to lodash ≥ 4.17.21
  ```bash
  npm install lodash@latest
  ```

### [SAST] A02 — JWT Without Expiration
- **File:** `src/auth/auth.service.ts:23`
- **Pattern:** `jwt.sign(payload, secret)` — no `expiresIn` option
- **Risk:** Tokens never expire — if stolen, permanently valid
- **Fix:** Add `expiresIn: '15m'` for access tokens, `'7d'` for refresh tokens

### [SAST] A07 — Missing Rate Limiting on /auth/login
- **File:** `src/auth/auth.controller.ts:12`
- **Pattern:** POST /auth/login has no rate limiter — brute-force attack surface
- **Fix:** Add `@Throttle(5, 60)` (NestJS) — max 5 attempts per 60 seconds

---

## Medium Severity

### [SAST] A05 — CORS Wildcard in Production Config
- **File:** `src/main.ts:8`
- **Pattern:** `app.enableCors()` without origin restriction
- **Fix:**
  ```typescript
  app.enableCors({ origin: process.env.ALLOWED_ORIGINS?.split(',') });
  ```

### [SCA] express 4.18.1 — Path Traversal
- **CVE:** CVE-2024-XXXXX
- **CVSS:** 5.3 (Medium)
- **Fix:** `npm install express@latest`

---

## What Automated Scanning Cannot Catch

This scan covers ~40% of possible vulnerabilities. The following require manual review:

- **Business logic flaws** — authorization gaps specific to your domain (e.g., can user A see user B's orders?)
- **Race conditions** — concurrent request handling vulnerabilities
- **Insecure direct object references** — requires understanding of who can access what
- **Second-order injection** — data stored now, executed later
- **Cryptographic protocol choices** — requires expert review

**Recommended next step:** Schedule a threat modeling session with a security specialist
to cover the business logic layer.

---

## Dependency Update Commands

```bash
# Node.js — update vulnerable packages
npm install lodash@latest express@latest

# Verify after update
npm audit

# Python
pip install --upgrade package1 package2
pip-audit

# Java
mvn versions:use-latest-releases -DincludeFilter="groupId:artifactId"
```
```

## Examples

### Example 1 — Day 1 security baseline (no running app needed)

```
/tw-security-audit mode=scan
```

### Example 2 — Full audit with DAST against local dev server

```
/tw-security-audit mode=full target=http://localhost:3000
```

### Example 3 — Python project, high severity only

```
/tw-security-audit stack=python severity_threshold=high
```

### Example 4 — Specific OWASP categories

```
/tw-security-audit owasp_categories=A01,A02,A03 mode=scan
```

## Dependencies

- **Node.js:** `npm audit` (built-in)
- **Python:** `pip-audit` (`pip install pip-audit`) or `safety` (`pip install safety`)
- **Java:** OWASP Dependency Check Maven plugin or `./gradlew dependencyCheckAnalyze`
- **Go:** `govulncheck` (`go install golang.org/x/vuln/cmd/govulncheck@latest`)
- **.NET:** `dotnet list package --vulnerable`
- **DAST:** Docker (for OWASP ZAP container) — only required for `mode=dast` or `mode=full`

## Notes

- Always run `mode=scan` first — it requires no running application and catches the majority of issues
- Never run `mode=full` (active DAST scan) against production — use a staging environment
- Dependency vulnerabilities with CVSS ≥ 7.0 should block deployment
- Secrets found in code must be rotated immediately, not just removed from source
- This skill is a baseline scan — it does not replace a professional penetration test
- Pair with `/tw-compliance-audit` to map security findings to regulatory requirements
