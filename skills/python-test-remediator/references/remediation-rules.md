# Remediation Rules

Apply **`references/coverage-targets.md`** for tier assignment and post-remediation coverage.py checks.

## When the report says `create-test`

- Create `test_module_name.py` under the `tests/` directory (or `tests/unit/` if project uses subdirectories).
- Assign a **coverage tier (A / B / C)** from `coverage-targets.md` before writing tests.
- Cover the smallest set of behaviors that provide meaningful regression protection **and** move line coverage toward the tier target:
  - happy path
  - branch or fallback path
  - error path (exceptions, validation failures)
- Add tests for **public function/method** behavior first; test private functions only if they have complex logic.
- Prefer one focused test module over many fragmented ones.
- Use **parameterized tests** (`@pytest.mark.parametrize` or `unittest.subTest`) when several cases share the same arrange/act shape (see governor `test-generation-standards.md` for when to avoid them).

## When the report says `update-test`

- Read the failing test and the production module side by side.
- Look first for:
  - new function parameters or dependencies
  - new method calls or collaborators
  - changed return types or attributes
  - changed exception flow
- Repair fixture setup before changing assertions.
- If all failures stem from one missing mock or patch, fix that in shared setup first.

## When the report says `review-test`

- Explain the ambiguity.
- Identify what evidence is missing.
- Prefer manual review to speculative code generation.

## Verification

- Run the narrowest possible test target first.
- If the new or updated tests pass, optionally run the containing package.
- **After** all edits for a batch, run `pytest --cov=. --cov-report=xml --cov-report=html --cov-report=term-missing` and record **line coverage per remediated module** vs tier target (`coverage-targets.md`).
- For `update-test`, prefer **no regression**: tests green; module coverage should not drop without justification.
- Report when verification or coverage.py could not be completed (environment, time, or skipped by user).

## File naming conventions

### pytest style (default)

```
src/services/data_processor.py  →  tests/test_data_processor.py
src/adapters/csv_parser.py      →  tests/test_csv_parser.py
```

Or with subdirectories:

```
src/services/data_processor.py  →  tests/unit/test_data_processor.py
src/adapters/csv_parser.py      →  tests/unit/test_csv_parser.py
```

### Alternative naming

```
src/services/data_processor.py  →  tests/data_processor_test.py
```

Match the existing project convention.

## Mock and patch patterns

### pytest-mock (if available)

```python
def test_fetch_data_from_api(mocker):
    # Arrange
    mock_get = mocker.patch('module.requests.get')
    mock_get.return_value.json.return_value = {"data": "test"}

    # Act
    result = fetch_data()

    # Assert
    assert result == {"data": "test"}
    mock_get.assert_called_once()
```

### unittest.mock (standard library)

```python
from unittest.mock import patch, Mock

def test_fetch_data_from_api():
    # Arrange
    with patch('module.requests.get') as mock_get:
        mock_get.return_value.json.return_value = {"data": "test"}

        # Act
        result = fetch_data()

        # Assert
        assert result == {"data": "test"}
        mock_get.assert_called_once()
```

## Fixture patterns (pytest)

### Shared setup

```python
import pytest

@pytest.fixture
def processor():
    """Provide a DataProcessor instance for tests"""
    return DataProcessor(config={"mode": "test"})

def test_process_data(processor):
    result = processor.process({"key": "value"})
    assert result is not None
```

### Cleanup with yield

```python
@pytest.fixture
def temp_file():
    """Create and cleanup temp file"""
    file_path = "/tmp/test_file.txt"
    with open(file_path, "w") as f:
        f.write("test")

    yield file_path

    # Cleanup
    if os.path.exists(file_path):
        os.remove(file_path)
```

## Common update-test scenarios

### New function parameter added

**Before:**
```python
def test_calculate_total():
    result = calculate_total(100)
    assert result == 110  # Assumes 10% tax
```

**After:**
```python
def test_calculate_total():
    result = calculate_total(100, tax_rate=0.1)  # New parameter
    assert result == 110
```

### New dependency introduced

**Before:**
```python
class DataProcessor:
    def __init__(self):
        pass
```

**After:**
```python
class DataProcessor:
    def __init__(self, logger):  # New dependency
        self.logger = logger
```

**Test update:**
```python
from unittest.mock import Mock

def test_process_data():
    mock_logger = Mock()  # Add mock for new dependency
    processor = DataProcessor(logger=mock_logger)
    result = processor.process({"data": "test"})
    assert result is not None
```

### Changed exception type

**Before:**
```python
def test_invalid_input_raises_error():
    with pytest.raises(ValueError):
        process_data(None)
```

**After:**
```python
def test_invalid_input_raises_error():
    with pytest.raises(TypeError):  # Exception type changed
        process_data(None)
```
