# Secrets & Configuration Guide

This guide covers how to manage credentials and configuration for tw-ai-toolkit
across different environments: local development, CI/CD, and enterprise secret managers.

---

## Configuration Hierarchy

Settings are resolved in this order (highest priority first):

```
1. Environment variables   TW_* vars from .env or system environment
        ↓ (fallback)
2. Project config          .ai/config.json in the consumer repo
        ↓ (fallback)
3. Toolkit defaults        .ai/toolkit/config/defaults.json
```

**Rule:** Never put secrets in config.json. Config is committed to git — secrets are not.

---

## Option 1 — .env File (Local Development)

The simplest approach. Credentials live in a `.env` file that is gitignored.

### Setup

```bash
# Copy the template
cp .ai/toolkit/config/.env.example .env

# Fill in your values
nano .env
```

### .env format

```bash
# GitHub
TW_GITHUB_TOKEN=github_pat_xxxxxxxxxxxxxxxxxxxx

# Jira
TW_JIRA_HOST=https://your-org.atlassian.net
TW_JIRA_EMAIL=you@company.com
TW_JIRA_API_TOKEN=ATATxxxxxxxxxxxxxxxx
```

### Verify .env is gitignored

```bash
grep -q "\.env" .gitignore && echo "OK — .env is gitignored" || echo "WARNING: add .env to .gitignore"
```

### Enable in config.json

```json
{
  "env_file": ".env",
  "secrets": {
    "provider": "env_file"
  }
}
```

---

## Option 2 — CI/CD Secrets

For GitHub Actions, GitLab CI, or other CI systems. Secrets are stored in the CI platform
and injected as environment variables at runtime — no `.env` file needed.

### GitHub Actions

Store secrets in: **Repository → Settings → Secrets and variables → Actions**

```yaml
# .github/workflows/your-workflow.yml
env:
  TW_GITHUB_TOKEN: ${{ secrets.TW_GITHUB_TOKEN }}
  TW_JIRA_HOST: ${{ secrets.TW_JIRA_HOST }}
  TW_JIRA_EMAIL: ${{ secrets.TW_JIRA_EMAIL }}
  TW_JIRA_API_TOKEN: ${{ secrets.TW_JIRA_API_TOKEN }}
```

### GitLab CI

Store secrets in: **Settings → CI/CD → Variables**

```yaml
# .gitlab-ci.yml
variables:
  TW_GITHUB_TOKEN: $TW_GITHUB_TOKEN    # from GitLab CI variables
  TW_JIRA_HOST: $TW_JIRA_HOST
```

---

## Option 3 — AWS Secrets Manager

For teams already using AWS. Store all toolkit secrets as a single JSON secret.

### Secret structure

Create a secret named `tw-ai-toolkit/<env>` with this JSON value:

```json
{
  "TW_GITHUB_TOKEN": "github_pat_xxxxxxxxxxxxxxxxxxxx",
  "TW_JIRA_HOST": "https://your-org.atlassian.net",
  "TW_JIRA_EMAIL": "service-account@company.com",
  "TW_JIRA_API_TOKEN": "ATATxxxxxxxxxxxxxxxx"
}
```

### Enable in config.json

```json
{
  "secrets": {
    "provider": "aws_secrets_manager",
    "aws": {
      "region": "us-east-1",
      "secret_name": "tw-ai-toolkit/production"
    }
  }
}
```

### Load secrets at runtime

```bash
# Load all keys from the secret into the current shell
eval $(aws secretsmanager get-secret-value \
  --secret-id tw-ai-toolkit/production \
  --query SecretString \
  --output text | python3 -c "
import sys, json
for k, v in json.load(sys.stdin).items():
    print(f'export {k}={v}')
")
```

Or use `aws-vault` for session-based loading:

```bash
aws-vault exec your-profile -- claude
```

### Required IAM permissions

```json
{
  "Effect": "Allow",
  "Action": ["secretsmanager:GetSecretValue"],
  "Resource": "arn:aws:secretsmanager:us-east-1:*:secret:tw-ai-toolkit/*"
}
```

---

## Option 4 — HashiCorp Vault

### Store secrets

```bash
vault kv put secret/tw-ai-toolkit/production \
  TW_GITHUB_TOKEN="github_pat_..." \
  TW_JIRA_API_TOKEN="ATAT..."
```

### Enable in config.json

```json
{
  "secrets": {
    "provider": "vault",
    "vault": {
      "addr": "https://vault.company.com",
      "path": "secret/tw-ai-toolkit/production",
      "auth_method": "token"
    }
  }
}
```

### Load secrets at runtime

```bash
eval $(vault kv get -format=json secret/tw-ai-toolkit/production \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)['data']['data']
for k, v in data.items():
    print(f'export {k}={v}')
")
```

---

## Option 5 — GCP Secret Manager

### Store secrets

```bash
echo -n '{"TW_GITHUB_TOKEN":"...","TW_JIRA_API_TOKEN":"..."}' \
  | gcloud secrets create tw-ai-toolkit --data-file=-
```

### Enable in config.json

```json
{
  "secrets": {
    "provider": "gcp_secret_manager",
    "gcp": {
      "project_id": "your-project-id",
      "secret_name": "tw-ai-toolkit"
    }
  }
}
```

### Load secrets at runtime

```bash
eval $(gcloud secrets versions access latest \
  --secret="tw-ai-toolkit" \
  | python3 -c "
import sys, json
for k, v in json.load(sys.stdin).items():
    print(f'export {k}={v}')
")
```

---

## Secret Naming Conventions

All toolkit secrets follow this pattern:

```
TW_<SERVICE>_<CREDENTIAL>

Examples:
  TW_GITHUB_TOKEN
  TW_JIRA_HOST
  TW_JIRA_EMAIL
  TW_JIRA_API_TOKEN
  TW_SLACK_BOT_TOKEN
```

MCP server `config.json` files document which `TW_*` vars are required
and what they map to internally. See `mcp/<server>/config.json`.

---

## Rotation Strategy

| Credential | Recommended rotation | How to rotate |
|---|---|---|
| GitHub PAT | Every 90 days | GitHub → Settings → Developer settings → Rotate token |
| Jira API token | Every 90 days | id.atlassian.com → Security → Rotate token |
| AWS credentials | Per IAM policy | Use IAM roles instead of long-lived keys when possible |
| Vault token | Short TTL + renewal | Use AppRole or AWS IAM auth for automatic renewal |

**After rotation:** Update the secret in your provider and verify with `bash scripts/validate-config.sh`.

---

## Security Checklist

Before committing or sharing your repo:

- [ ] `.env` is in `.gitignore`
- [ ] No secrets in `.ai/config.json`
- [ ] No secrets in any `skill.md`, `agent.md`, or other component files
- [ ] No secrets in `CLAUDE.md` or `.cursorrules`
- [ ] `.env.toolkit.example` contains only placeholder values
- [ ] MCP server logs do not contain credential values (`validate-config.sh --check-logs`)

---

## Validating Your Configuration

```bash
# From the consumer repo root
bash .ai/toolkit/scripts/validate-config.sh
```

This checks:
- `.ai/config.json` is valid JSON and matches the schema
- All required env vars for enabled MCP servers are set
- Installed toolkit version matches `toolkit_version` in config
