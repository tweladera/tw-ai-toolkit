---
name: stack-health-check
description: Comprehensive Day 1 assessment of any existing project — detects tech stack, measures current test coverage, evaluates CI health, checks dependency freshness, identifies security debt, and produces an executive summary plus technical detail report. The consultant's first deliverable.
status: stable
version_added: v0.5.0
compatible_with:
  claude_code: full
  cursor: partial
  codex: none
parameters:
  - name: depth
    type: string
    required: false
    default: "standard"
    description: "'quick' for a 5-minute snapshot (stack + coverage + CI status), 'standard' for full assessment (default), 'deep' for standard + security + dependency analysis."
  - name: output
    type: string
    required: false
    default: "report"
    description: "'report' for full technical report, 'executive' for a management-facing summary (2 pages max), 'both'."
tags:
  - consulting
  - assessment
  - onboarding
  - discovery
  - health-check
  - qa
invocation: tw-stack-health-check
---

# stack-health-check

## Description

When a consultant joins a new client project, the first question is always:
**"What does this codebase actually look like?"**

Without a structured answer, the first 2 weeks are spent wandering — reading files, running
tests that may or may not pass, asking developers who may or may not know the full picture.

`stack-health-check` produces a comprehensive technical health assessment in one run.
It gives the consultant a shared language with the client team, identifies the highest-risk
areas immediately, and generates the evidence base for the QA strategy conversation.

**What it measures:**

| Dimension | What it detects |
|---|---|
| Stack | Languages, frameworks, databases, message queues, cloud services |
| Test coverage | Current coverage %, test file inventory, coverage tools |
| CI health | Pipeline configuration, passing rate, average duration |
| Dependency freshness | Outdated packages, deprecated libraries, known CVEs |
| Security posture | Basic SAST findings, secret scanning |
| Architecture | Monolith vs microservices, API surface, external integrations |
| Technical debt signals | TODOs, FIXMEs, commented-out code, large files, cyclomatic complexity |
| Documentation | README quality, API docs, architecture diagrams |

## When to Use

- Day 1 or Day 2 of any new client engagement
- When taking over an existing project from another team
- When a client asks "is our codebase in good shape?"
- Before proposing a quality improvement initiative

Triggers: "assess the project", "health check", "what's the state of the codebase",
"technical assessment", "how much test debt do we have", "day 1 analysis".

## Instructions

### Step 1 — Stack Detection

```bash
echo "=== RUNTIME & LANGUAGES ==="
ls package.json requirements.txt Pipfile pom.xml build.gradle \
   go.mod Cargo.toml *.csproj Gemfile 2>/dev/null | head -10

# Node.js version
node --version 2>/dev/null || cat .nvmrc .node-version 2>/dev/null
# Python version
python3 --version 2>/dev/null || cat .python-version 2>/dev/null
# Java version
java -version 2>/dev/null | head -1

echo "=== FRAMEWORKS (Node.js) ==="
cat package.json 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
all_deps={**d.get('dependencies',{}),**d.get('devDependencies',{})}
frameworks=['nestjs','express','fastify','koa','hapi','next','nuxt','remix',
            'react','vue','angular','svelte','electron']
for f in frameworks:
    match=[k for k in all_deps if f in k.lower()]
    if match: print(f'  {f}: {match[0]} {all_deps[match[0]]}')
"

echo "=== DATABASE ==="
rg "typeorm|sequelize|prisma|mongoose|pg|mysql2|sqlite" package.json 2>/dev/null
rg "sqlalchemy|psycopg2|pymongo|django.db" requirements.txt 2>/dev/null
rg "spring-data|hibernate|jpa" pom.xml build.gradle 2>/dev/null

echo "=== MESSAGE QUEUES / EVENT STREAMING ==="
rg "kafka|rabbitmq|sqs|sns|pubsub|nats|amqplib" package.json requirements.txt pom.xml 2>/dev/null

echo "=== CLOUD / INFRASTRUCTURE ==="
ls Dockerfile docker-compose*.yml kubernetes/ k8s/ terraform/ cdk/ serverless.yml 2>/dev/null
rg "aws-sdk|@aws-sdk|boto3|google-cloud|azure" package.json requirements.txt 2>/dev/null

echo "=== CI PLATFORM ==="
ls .github/workflows/ 2>/dev/null && echo "GitHub Actions"
ls .gitlab-ci.yml 2>/dev/null && echo "GitLab CI"
ls azure-pipelines.yml 2>/dev/null && echo "Azure DevOps"
ls Jenkinsfile 2>/dev/null && echo "Jenkins"
ls .circleci/config.yml 2>/dev/null && echo "CircleCI"
ls bitbucket-pipelines.yml 2>/dev/null && echo "Bitbucket Pipelines"
```

### Step 2 — Test Coverage Assessment

```bash
echo "=== TEST FILE INVENTORY ==="
echo "TypeScript spec files:"
find . -name "*.spec.ts" -o -name "*.test.ts" 2>/dev/null | grep -v node_modules | wc -l

echo "Python test files:"
find . -name "test_*.py" -o -name "*_test.py" 2>/dev/null | wc -l

echo "Java test files:"
find . -name "*Test.java" -o -name "*Spec.java" 2>/dev/null | wc -l

echo "E2E test files:"
find . -name "*.cy.ts" -o -name "*.spec.ts" -path "*/e2e/*" \
       -o -name "*.feature" 2>/dev/null | grep -v node_modules | wc -l

echo "=== COVERAGE REPORTS ==="
# Istanbul/nyc (TypeScript/JS)
cat coverage/coverage-summary.json 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
t=d.get('total',{})
for k in ['lines','statements','functions','branches']:
    pct=t.get(k,{}).get('pct',0)
    print(f'  {k}: {pct}%')
"

# Python coverage
cat coverage.xml 2>/dev/null | python3 -c "
import sys
from xml.etree import ElementTree as ET
tree=ET.parse(sys.stdin)
root=tree.getroot()
print(f'  lines: {float(root.get(\"line-rate\",0))*100:.1f}%')
print(f'  branches: {float(root.get(\"branch-rate\",0))*100:.1f}%')
"

# Jacoco (Java)
find . -name "jacoco.xml" 2>/dev/null | head -1 | xargs cat 2>/dev/null | \
  python3 -c "
import sys
from xml.etree import ElementTree as ET
tree=ET.parse(sys.stdin)
for counter in tree.findall('.//counter[@type=\"LINE\"]'):
    covered=int(counter.get('covered',0))
    missed=int(counter.get('missed',0))
    total=covered+missed
    pct=covered/total*100 if total>0 else 0
    print(f'  lines: {pct:.1f}%')
    break
"
```

### Step 3 — CI Health Check

```bash
echo "=== CI PIPELINE ANALYSIS ==="
# GitHub Actions — list workflows and their last status
ls .github/workflows/*.yml 2>/dev/null | while read f; do
  echo "Workflow: $(basename $f)"
  grep "name:" "$f" | head -1
  grep "on:" "$f" | head -3
done

# GitLab CI — list stages and jobs
cat .gitlab-ci.yml 2>/dev/null | python3 -c "
import sys,yaml
d=yaml.safe_load(sys.stdin)
print('Stages:', d.get('stages',[]))
jobs=[k for k in d if not k.startswith('.')]
print(f'Jobs: {len(jobs)} ({jobs[:5]}...)')
"

echo "=== QUALITY GATES IN CI ==="
# Check if coverage thresholds exist
rg "coverage.*threshold|min.*coverage|lcov\|--check" \
  .github/workflows/*.yml .gitlab-ci.yml azure-pipelines.yml 2>/dev/null | head -5
```

### Step 4 — Dependency Health

```bash
echo "=== OUTDATED DEPENDENCIES ==="
# Node.js
npm outdated --json 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
for pkg,(info) in list(d.items())[:10]:
    print(f'  {pkg}: {info.get(\"current\")} → {info.get(\"latest\")}')
" 2>/dev/null

# Python
pip list --outdated --format=json 2>/dev/null | python3 -c "
import sys,json
for pkg in json.load(sys.stdin)[:10]:
    print(f'  {pkg[\"name\"]}: {pkg[\"version\"]} → {pkg[\"latest_version\"]}')
"

echo "=== ABANDONED/DEPRECATED PACKAGES ==="
# Check for known deprecated packages (Node.js)
rg "\"request\":|\"node-uuid\":|\"underscore\":|\"moment\":" package.json 2>/dev/null

echo "=== DEPENDENCY VULNERABILITY QUICK SCAN ==="
npm audit --audit-level=high 2>/dev/null | tail -5
```

### Step 5 — Technical Debt Signals

```bash
echo "=== TECHNICAL DEBT MARKERS ==="
echo "TODOs/FIXMEs:"
rg "TODO|FIXME|HACK|XXX" src/ --type ts --type py --type java | wc -l

echo "Commented-out code blocks:"
rg "^//.*\(|^#.*\(|//.*function |// *class " src/ | wc -l

echo "Large files (potential God classes):"
find src/ -name "*.ts" -o -name "*.py" -o -name "*.java" 2>/dev/null | \
  xargs wc -l 2>/dev/null | sort -rn | head -10

echo "=== DOCUMENTATION ==="
wc -l README.md 2>/dev/null
ls docs/ 2>/dev/null | head -10
ls openapi/ api/ swagger/ 2>/dev/null

echo "=== SECRETS EXPOSURE RISK ==="
rg "password\s*=\s*['\"][^'\"]{3,}|api_key\s*=\s*['\"]|secret\s*=\s*['\"]" \
  src/ -i | grep -v "test\|spec\|example\|placeholder\|your_" | head -5
```

### Step 6 — Generate Reports

#### Executive Summary (output=executive):

```markdown
# Technical Health Assessment — {{project_name}}

**Date:** YYYY-MM-DD   **Assessed by:** [Consultant Name]   **Depth:** Standard

---

## Overall Health Score: 52/100 ⚠️

| Dimension | Score | Status |
|---|---|---|
| Test Coverage | 4/20 | 🔴 Critical — 22% line coverage |
| CI/CD Health | 12/20 | 🟡 Partial — pipeline exists, no quality gates |
| Security Posture | 8/20 | 🟡 Partial — 3 high CVEs, no SAST |
| Dependency Health | 14/20 | 🟢 Good — 2 major versions behind |
| Architecture | 14/20 | 🟢 Good — clean separation, documented API |

---

## What Works Well

- Clear microservices separation (4 services, well-defined boundaries)
- OpenAPI spec exists for all services — good foundation for automated tests
- GitHub Actions pipeline exists and runs on every PR
- Dependencies are mostly current

---

## What Needs Immediate Attention

1. **Test coverage is critically low (22%)** — the majority of business logic has no tests.
   Any change carries significant regression risk. Estimated effort to reach 70%: 3-4 sprints.

2. **3 high-severity CVEs in production dependencies** — lodash and two transitive dependencies
   have known vulnerabilities. Update required before next production deployment.

3. **No security scanning in CI** — security findings are only caught if someone manually
   checks. A dependency scan takes 2 minutes and should be in every PR gate.

---

## Recommended First Steps (Prioritized)

| # | Action | Effort | Impact |
|---|---|---|---|
| 1 | Run security scan, fix CVSS ≥ 7.0 | 1 day | High |
| 2 | Add governance report to CI (coverage gate) | 0.5 days | High |
| 3 | Generate integration tests from OpenAPI spec | 2 days | High |
| 4 | Cover top 5 business logic modules with unit tests | 3-5 days | High |
| 5 | Generate QA Strategy document | 1 day | Medium |

---

**Full technical report available:** see `HEALTH_CHECK_TECHNICAL_YYYY-MM-DD.md`
```

#### Technical Report (output=report):

```markdown
# Technical Health Check — Full Report

**Project:** {{project_name}}
**Date:** YYYY-MM-DD
**Generated by:** /tw-stack-health-check | v0.5.0

---

## Stack Inventory

| Layer | Technology | Version | Status |
|---|---|---|---|
| Runtime | Node.js | 20.11.0 | ✅ Current LTS |
| Framework | NestJS | 10.3.2 | ✅ Current |
| Database | PostgreSQL (TypeORM) | pg 8.11.3 | ✅ Current |
| Message Queue | AWS SQS (aws-sdk v3) | 3.502.0 | ✅ Current |
| Frontend | React | 18.2.0 | ✅ Current |
| CI/CD | GitHub Actions | — | ✅ Active |
| Container | Docker + AWS ECS | — | ✅ Active |

---

## Test Coverage

| Service | Test Files | Line Coverage | Branch Coverage | Status |
|---|---|---|---|---|
| orders-service | 12 | 38% | 22% | 🔴 Critical |
| payments-service | 3 | 11% | 8% | 🔴 Critical |
| users-service | 18 | 71% | 58% | 🟡 Needs work |
| notifications-service | 0 | 0% | 0% | 🔴 No tests |
| Frontend (React) | 7 | 24% | 15% | 🔴 Critical |

**E2E tests:** 0 (no Cypress or Playwright found)
**Contract tests:** 0 (no Pact files found)

---

## CI Pipeline Health

- **Pipeline:** `.github/workflows/ci.yml`
- **Triggers:** PR + push to main
- **Stages:** install → lint → test → build
- **Missing stages:** coverage threshold enforcement, security scan, E2E, contract tests
- **Average duration:** ~4 minutes (fast — but incomplete)
- **Quality gates:** None (pipeline passes regardless of test coverage)

---

## Dependency Health

### Outdated (Major versions behind)

| Package | Current | Latest | Risk |
|---|---|---|---|
| lodash | 4.17.15 | 4.17.21 | 🔴 CVE-2021-23337 |
| @types/node | 16.18.x | 20.11.x | 🟡 Major version gap |
| webpack | 4.x | 5.x | 🟡 EOL approaching |

### CVEs Detected

| Package | CVE | CVSS | Description |
|---|---|---|---|
| lodash | CVE-2021-23337 | 7.2 | Prototype pollution |
| axios | CVE-2023-45857 | 6.5 | CSRF token exposure |

---

## Technical Debt Signals

- **TODOs/FIXMEs in source code:** 47
- **Files > 500 lines:** 8 (potential God classes)
  - `src/orders/order.service.ts` — 892 lines
  - `src/payments/payment.service.ts` — 634 lines
- **Commented-out code blocks:** 23
- **README:** Exists, last updated 8 months ago (may be stale)
- **API documentation:** OpenAPI spec exists ✅

---

## Next Steps

Run these toolkit commands to start improving:

\`\`\`bash
/tw-security-audit                          # Fix CVEs immediately
/tw-ts-test-governor                        # Full coverage gap analysis
/tw-integration-discovery source=openapi/  # Auto-generate integration tests
/tw-test-strategy-generator                 # Create the QA strategy document
/tw-pipeline-generator                      # Add quality gates to CI
\`\`\`
```

## Examples

### Example 1 — Quick snapshot for a first meeting

```
/tw-stack-health-check depth=quick output=executive
```

### Example 2 — Full assessment before proposing a quality initiative

```
/tw-stack-health-check depth=deep output=both
```

### Example 3 — Standard assessment, executive output only

```
/tw-stack-health-check output=executive
```

## Dependencies

- Source code in working directory
- For coverage reports: existing coverage output files (Istanbul JSON, coverage.xml, jacoco.xml)
- For dependency analysis: package managers installed (npm, pip, mvn/gradle)

## Notes

- This is an assessment skill — it reads, never modifies
- The health score is an indicator, not a benchmark — use it to prioritize conversation, not judge the team
- Always pair the executive summary with empathy: low coverage usually means "no time for tests", not negligence
- Follow with `/tw-test-strategy-generator` to produce the improvement plan
- Run again after 30 days to show progress — the delta is more valuable than the snapshot
