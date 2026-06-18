# Test Generation Template

Align naming, assertions, and fixture usage with **`python-unit-test-governor` → `references/test-generation-standards.md`** when in doubt.

## New test module outline (pytest)

```python
import pytest
from unittest.mock import Mock, patch

from module_name import ClassName


class TestClassName:
    """Tests for ClassName functionality"""

    @pytest.fixture
    def mock_dependency(self):
        """Mock for dependency"""
        return Mock()

    @pytest.fixture
    def subject(self, mock_dependency):
        """Create instance under test"""
        return ClassName(dependency=mock_dependency)

    def test_method_when_condition_expected_result(self, subject):
        """Test description"""
        # Arrange
        expected = "result"

        # Act
        result = subject.method("input")

        # Assert
        assert result == expected
```

## Alternative: unittest style

```python
import unittest
from unittest.mock import Mock, patch

from module_name import ClassName


class TestClassName(unittest.TestCase):
    """Tests for ClassName functionality"""

    def setUp(self):
        """Set up test fixtures"""
        self.mock_dependency = Mock()
        self.subject = ClassName(dependency=self.mock_dependency)

    def test_method_when_condition_expected_result(self):
        """Test description"""
        # Arrange
        expected = "result"

        # Act
        result = self.subject.method("input")

        # Assert
        self.assertEqual(result, expected)
```

## Function-level tests (pytest)

For modules with standalone functions (not classes):

```python
import pytest
from unittest.mock import patch

from module_name import process_data


def test_process_data_with_valid_input():
    """Process returns transformed data for valid input"""
    # Arrange
    input_data = {"id": 1, "name": "test"}

    # Act
    result = process_data(input_data)

    # Assert
    assert result["id"] == 1
    assert result["name"] == "TEST"  # Uppercase transformation


def test_process_data_with_invalid_input_raises_error():
    """Process raises ValueError for invalid input"""
    # Arrange
    invalid_data = None

    # Act & Assert
    with pytest.raises(ValueError, match="Input cannot be None"):
        process_data(invalid_data)


@patch('module_name.external_api_call')
def test_process_data_calls_external_api(mock_api):
    """Process should call external API with correct params"""
    # Arrange
    mock_api.return_value = {"status": "ok"}
    input_data = {"id": 1}

    # Act
    result = process_data(input_data)

    # Assert
    mock_api.assert_called_once_with(id=1)
    assert result["status"] == "ok"
```

## Branch and error coverage (tier A / B)

- For each **non-trivial** `if` / conditional expression / early return, add or extend a test that exercises the alternate path.
- For functions that **raise** exceptions, add at least one test with `pytest.raises` (or unittest `assertRaises`).
- Verify **mock calls** only when the contract matters (`assert_called_once()`, `assert_called_with()`); avoid over-specifying incidental calls.

## Parameterized outline (pytest)

When cases share structure:

```python
import pytest


@pytest.mark.parametrize("input_value,expected", [
    ("hello", "HELLO"),
    ("world", "WORLD"),
    ("", ""),
    ("Test123", "TEST123"),
])
def test_to_upper_various_inputs(input_value, expected):
    """to_upper should handle various string inputs"""
    result = to_upper(input_value)
    assert result == expected


@pytest.mark.parametrize("input_value,expected_error", [
    (None, TypeError),
    (123, TypeError),
    ([], TypeError),
])
def test_to_upper_invalid_types_raise_errors(input_value, expected_error):
    """to_upper should raise TypeError for non-string inputs"""
    with pytest.raises(expected_error):
        to_upper(input_value)
```

## unittest parameterized with subTest

```python
class TestToUpper(unittest.TestCase):
    def test_to_upper_various_inputs(self):
        """to_upper should handle various string inputs"""
        test_cases = [
            ("hello", "HELLO"),
            ("world", "WORLD"),
            ("", ""),
        ]

        for input_value, expected in test_cases:
            with self.subTest(input=input_value):
                result = to_upper(input_value)
                self.assertEqual(result, expected)
```

## Mocking external dependencies

### API calls

```python
from unittest.mock import patch


@patch('module.requests.get')
def test_fetch_user_from_api(mock_get):
    """fetch_user should call API and return parsed data"""
    # Arrange
    mock_get.return_value.json.return_value = {"id": 1, "name": "Alice"}
    mock_get.return_value.status_code = 200

    # Act
    result = fetch_user(1)

    # Assert
    assert result["name"] == "Alice"
    mock_get.assert_called_once_with("https://api.example.com/users/1")
```

### Database operations

```python
from unittest.mock import Mock, patch


def test_save_record_to_database():
    """save_record should insert data into database"""
    # Arrange
    mock_conn = Mock()
    mock_cursor = Mock()
    mock_conn.cursor.return_value.__enter__.return_value = mock_cursor

    # Act
    with patch('module.psycopg.connect', return_value=mock_conn):
        save_record({"id": 1, "data": "test"})

    # Assert
    mock_cursor.execute.assert_called_once()
    call_args = mock_cursor.execute.call_args[0]
    assert "INSERT" in call_args[0]
```

### File I/O

```python
from unittest.mock import mock_open, patch


def test_read_config_from_file():
    """read_config should parse JSON from file"""
    # Arrange
    mock_data = '{"setting": "value"}'
    m_open = mock_open(read_data=mock_data)

    # Act
    with patch('builtins.open', m_open):
        config = read_config("/path/to/config.json")

    # Assert
    assert config["setting"] == "value"
    m_open.assert_called_once_with("/path/to/config.json", "r")
```

## update-test checklist

When updating existing tests:

- [ ] Add any newly required mocks or patches
- [ ] Update fixture setup in `setUp()` or `@pytest.fixture`
- [ ] Stub new function/method calls (`return_value`, `side_effect`)
- [ ] Update assertions to match current behavior
- [ ] Remove assertions that depended on prior implementation details
- [ ] Re-run tests + coverage.py
- [ ] Confirm line coverage for the module under test still meets or improves toward the assigned tier (`references/coverage-targets.md`)

## Fixture setup patterns

### pytest fixture with cleanup

```python
@pytest.fixture
def database_connection():
    """Provide database connection with cleanup"""
    conn = create_connection()
    yield conn
    conn.close()


def test_query_database(database_connection):
    result = database_connection.execute("SELECT 1")
    assert result is not None
```

### pytest fixture with scope

```python
@pytest.fixture(scope="module")
def expensive_resource():
    """Create once per module"""
    resource = create_expensive_resource()
    yield resource
    resource.cleanup()
```

### unittest setUp/tearDown

```python
class TestDatabaseOperations(unittest.TestCase):
    def setUp(self):
        """Run before each test"""
        self.conn = create_connection()

    def tearDown(self):
        """Run after each test"""
        self.conn.close()

    def test_query(self):
        result = self.conn.execute("SELECT 1")
        self.assertIsNotNone(result)
```

## Testing async code (pytest-asyncio)

```python
import pytest


@pytest.mark.asyncio
async def test_async_function():
    """Test async function execution"""
    # Arrange
    input_data = {"id": 1}

    # Act
    result = await async_process(input_data)

    # Assert
    assert result["processed"] is True
```

## Testing exceptions and edge cases

### Multiple exception types

```python
def test_validate_input_handles_various_errors():
    """validate_input should raise appropriate exceptions"""
    # None input
    with pytest.raises(TypeError, match="Input cannot be None"):
        validate_input(None)

    # Empty string
    with pytest.raises(ValueError, match="Input cannot be empty"):
        validate_input("")

    # Invalid format
    with pytest.raises(ValueError, match="Invalid format"):
        validate_input("invalid")
```

### Edge cases

```python
@pytest.mark.parametrize("input_value,description", [
    ([], "empty list"),
    ([1], "single item"),
    ([1, 2, 3, 4, 5], "multiple items"),
    ([None, 1, None], "list with None values"),
])
def test_process_list_edge_cases(input_value, description):
    """process_list should handle edge cases correctly"""
    result = process_list(input_value)
    assert isinstance(result, list)
    assert len(result) <= len(input_value)
```
