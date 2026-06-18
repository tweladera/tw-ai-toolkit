# Coverage targets after remediation

These are **default targets** for **line coverage on the module under test** (coverage.py, unit test execution). A repository or user may define stricter floors in pytest.ini or CI; those override these defaults when higher.

## Tiers (assign before generating tests)

| Tier | Typical production modules | Line coverage target | Rationale |
|------|---------------------------|----------------------|-----------|
| **A** | Business logic, services, processors, validators, transformers with branching | **≥ 90%** | Core business logic; regressions are expensive. |
| **B** | Adapters with transformation, parsing, retries, query building, error handling | **≥ 80%** | Real logic, but some branches may depend on I/O contracts hard to hit in pure unit tests. |
| **C** | Thin facades, simple helpers, delegation with little branching | **≥ 70%** | Meaningful behavior covered; chasing 90% often yields brittle tests. |

## Modules out of tier chasing

Do **not** inflate coverage artificially for:

- Dataclasses / NamedTuples / TypedDict with no logic
- Configuration files with only constants
- Empty `__init__.py` files
- Code the governor marked `no-test-needed`

For those, follow the report; do not apply tier A/B targets.

## When targets are not reachable in one pass

Document in the remediation summary:

- **Unreachable branch:** e.g. defensive `except`, platform-specific path, requires integration test
- **Partial mock:** dependency behavior cannot be exercised without an integration test — recommend integration follow-up
- **review-test:** halt numeric target until ambiguity is resolved

## Verification commands (pytest + coverage.py)

After changing tests for module `src/services/data_processor.py`:

```bash
pytest --cov=src --cov-report=xml --cov-report=html --cov-report=term-missing
```

Then inspect:

- HTML: `htmlcov/index.html` → navigate to the module
- XML: `coverage.xml` → find module and read line coverage percentage
- Terminal: Shows missing lines directly

Optional: run only the relevant test to save time:

```bash
pytest tests/test_data_processor.py --cov=src/services/data_processor --cov-report=term-missing
```

## Coverage.py configuration

Add to `pyproject.toml` or `.coveragerc`:

```toml
[tool.coverage.run]
source = ["src"]
omit = ["tests/*", "*/venv/*", "*/__pycache__/*"]

[tool.coverage.report]
fail_under = 80
show_missing = true
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise AssertionError",
    "raise NotImplementedError",
    "if __name__ == .__main__.:",
    "if TYPE_CHECKING:",
]
```

## Reporting in the remediation output

For each remediated production module, add one line:

`Module` | `Tier` | `Line coverage (after)` | `Meets target?` | `Notes`

If coverage.py was not run, state `not verified` and the reason.

## Example output table

| Module | Tier | Line coverage (after) | Meets target? | Notes |
|--------|------|----------------------|---------------|-------|
| `src/services/data_processor.py` | A | 92% | ✅ Yes | All branches covered |
| `src/adapters/csv_parser.py` | B | 85% | ✅ Yes | Exception paths tested |
| `src/utils/string_helpers.py` | C | 74% | ✅ Yes | Edge cases covered |
| `src/adapters/api_client.py` | B | 76% | ⚠️ No (target 80%) | Network error path needs integration test |
