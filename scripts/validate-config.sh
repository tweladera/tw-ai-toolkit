#!/usr/bin/env bash
# validate-config.sh
# Validates a consumer repo's .ai/config.json against the schema and checks
# that required env vars for enabled MCP servers are present.
#
# Run from the consumer repo root:
#   bash .ai/toolkit/scripts/validate-config.sh [--env-file <path>]
#
# Options:
#   --env-file <path>   Path to .env file (default: value from config.json or .env)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$SCRIPT_DIR/.."

# Detect if running from toolkit root (dev) or consumer repo
if [[ -f "$TOOLKIT_ROOT/registry.json" && "$(pwd)" == "$TOOLKIT_ROOT" ]]; then
    echo "[tw-ai-toolkit] Running validate-config.sh from toolkit root — skipping (no consumer config here)."
    exit 0
fi

CONSUMER_ROOT="$(pwd)"
CONFIG_PATH="$CONSUMER_ROOT/.ai/config.json"
SCHEMA_PATH="$TOOLKIT_ROOT/config/config.schema.json"
MCP_DIR="$TOOLKIT_ROOT/mcp"

ARG_ENV_FILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --env-file) ARG_ENV_FILE="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

echo ""
echo "[tw-ai-toolkit] Validating consumer config..."
echo ""

python3 - "$CONFIG_PATH" "$SCHEMA_PATH" "$MCP_DIR" "$TOOLKIT_ROOT" "$ARG_ENV_FILE" "$CONSUMER_ROOT" << 'PYTHON'
import sys, os, re, json

config_path   = sys.argv[1]
schema_path   = sys.argv[2]
mcp_dir       = sys.argv[3]
toolkit_root  = sys.argv[4]
arg_env_file  = sys.argv[5]
consumer_root = sys.argv[6]

errors   = []
warnings = []

def err(msg):  errors.append(f"  ERROR   {msg}")
def warn(msg): warnings.append(f"  WARN    {msg}")
def ok(msg):   print(f"  [OK] {msg}")

# ── 1. config.json exists and is valid JSON ───────────────────────────────────

if not os.path.exists(config_path):
    print(f"  ERROR   .ai/config.json not found at {config_path}")
    print(f"\n  Run /tw-install-toolkit or bash .ai/toolkit/scripts/install.sh to set up.")
    sys.exit(1)

try:
    with open(config_path) as f:
        config = json.load(f)
    ok(".ai/config.json is valid JSON")
except json.JSONDecodeError as e:
    print(f"  ERROR   .ai/config.json is not valid JSON: {e}")
    sys.exit(1)

# ── 2. Required fields ────────────────────────────────────────────────────────

if "toolkit_version" not in config:
    err("toolkit_version is required in .ai/config.json")
else:
    version = config["toolkit_version"]
    if not re.match(r'^v\d+\.\d+\.\d+$', version):
        err(f"toolkit_version '{version}' must be in vMAJOR.MINOR.PATCH format")
    else:
        # Check installed version matches config
        try:
            import subprocess
            installed = subprocess.check_output(
                ["git", "describe", "--tags", "--exact-match"],
                cwd=os.path.join(consumer_root, ".ai", "toolkit"),
                stderr=subprocess.DEVNULL
            ).decode().strip()
            if installed != version:
                warn(f"toolkit_version '{version}' in config does not match installed '{installed}' — run /tw-update")
            else:
                ok(f"toolkit_version {version} matches installed submodule")
        except Exception:
            warn("Could not verify installed submodule version against toolkit_version")

# ── 3. Load .env file ─────────────────────────────────────────────────────────

env_file = arg_env_file or config.get("env_file", ".env")
env_path = os.path.join(consumer_root, env_file)
env_vars = {}

if os.path.exists(env_path):
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                k, _, v = line.partition('=')
                env_vars[k.strip()] = v.strip().strip('"').strip("'")
    ok(f".env loaded from {env_file} ({len(env_vars)} variables)")
else:
    # Also check actual environment
    for k, v in os.environ.items():
        if k.startswith('TW_'):
            env_vars[k] = v
    if env_vars:
        warn(f"{env_file} not found — using TW_* vars from system environment ({len(env_vars)} found)")
    else:
        warn(f"{env_file} not found and no TW_* vars in environment — MCP servers may not work")

# ── 4. Validate MCP server env vars ──────────────────────────────────────────

enabled_mcp = config.get("mcp_servers", [])

if not enabled_mcp:
    ok("No MCP servers enabled — skipping env var checks")
else:
    for server_entry in enabled_mcp:
        server_name = server_entry.get("name", "")
        server_config_path = os.path.join(mcp_dir, server_name, "config.json")

        if not os.path.exists(server_config_path):
            warn(f"MCP server '{server_name}' not found in toolkit — check name in .ai/config.json")
            continue

        with open(server_config_path) as f:
            server_config = json.load(f)

        required_env = server_config.get("required_env", [])
        all_present = True
        for req in required_env:
            var_name = req["var"]
            if var_name not in env_vars and var_name not in os.environ:
                err(f"MCP server '{server_name}' requires {var_name} — not found in {env_file} or environment")
                err(f"         Description: {req.get('description', '')}")
                all_present = False

        if all_present:
            ok(f"MCP server '{server_name}' — all required env vars present")

# ── 5. Schema validation (basic field types) ──────────────────────────────────

valid_component_types = {"skills", "agents", "prompts", "rules", "hooks", "mcp_servers"}
enabled = config.get("enabled_components", list(valid_component_types))
invalid = set(enabled) - valid_component_types
if invalid:
    err(f"enabled_components contains unknown types: {invalid}")

update_strategy = config.get("update_strategy", "manual")
if update_strategy not in ("manual", "dependabot"):
    err(f"update_strategy must be 'manual' or 'dependabot', got '{update_strategy}'")

secrets = config.get("secrets", {})
valid_providers = {"env_file", "aws_secrets_manager", "vault", "gcp_secret_manager", "azure_key_vault"}
provider = secrets.get("provider", "env_file")
if provider not in valid_providers:
    err(f"secrets.provider must be one of {valid_providers}, got '{provider}'")

# ── Summary ───────────────────────────────────────────────────────────────────

print("")
print("─" * 52)
for e in errors:   print(e)
for w in warnings: print(w)
if errors or warnings: print("")

total = len(errors)
print(f"  {total} errors, {len(warnings)} warnings")
if total > 0:
    print("  Status: FAIL")
    sys.exit(1)
else:
    print("  Status: PASS")
PYTHON
