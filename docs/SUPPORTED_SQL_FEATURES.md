# DAoC SQL to Roblox Converter - Supported SQL Features

## Overview

This document describes the SQL features and syntax supported by the DAoC SQL to Roblox Converter plugin.

## Supported SQL Statements

### CREATE TABLE

The converter parses `CREATE TABLE` statements to extract column definitions:

```sql
CREATE TABLE IF NOT EXISTS `ability` (
  `AbilityID` int(11) NOT NULL AUTO_INCREMENT,
  `KeyName` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `Name` varchar(255) NOT NULL,
  `InternalID` int(11) NOT NULL DEFAULT 0,
  `Description` text NOT NULL,
  `IconID` int(11) NOT NULL,
  `Implementation` varchar(255) DEFAULT NULL,
  `LastTimeRowUpdated` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  PRIMARY KEY (`AbilityID`),
  UNIQUE KEY `U_Ability_KeyName` (`KeyName`)
) ENGINE=InnoDB AUTO_INCREMENT=371 DEFAULT CHARSET=utf8mb3;
```

**Supported Features:**
- `IF NOT EXISTS` clause
- Backtick column names (` `column_name` `)
- Data types with size specifications (e.g., `INT(11)`, `VARCHAR(255)`)
- `NOT NULL` constraint
- `DEFAULT` values
- `AUTO_INCREMENT` flag
- `CHARACTER SET` and `COLLATE` specifications
- `PRIMARY KEY` and `UNIQUE KEY` constraints
- `ENGINE` and `CHARSET` table options

### REPLACE INTO

The converter parses `REPLACE INTO` statements for data extraction:

```sql
REPLACE INTO `ability` (`AbilityID`, `KeyName`, `Name`, `InternalID`, `Description`, `IconID`, `Implementation`, `LastTimeRowUpdated`) VALUES
	(1, 'Augmented Strength', 'Augmented Strength', 129, 'Description here', 0, 'Implementation', '2000-01-01 00:00:00'),
	(2, 'Stag', 'Stag %n', 130, 'Complex description...', 480, NULL, '2000-01-01 00:00:00');
```

**Supported Features:**
- Explicit column list
- Multiple value tuples per statement
- Proper escaping of quotes within strings

### INSERT INTO

The converter also supports `INSERT INTO` statements:

```sql
INSERT INTO `spell` (`SpellID`, `Name`, `Description`) VALUES
	(1, 'Test Spell', 'A test spell description');
```

## Supported Data Types

### Numeric Types

| SQL Type | Lua Type | Example Input | Example Output |
|----------|----------|---------------|----------------|
| `INT` | number | `123` | `123` |
| `INTEGER` | number | `456` | `456` |
| `TINYINT` | number | `1` | `1` |
| `SMALLINT` | number | `100` | `100` |
| `MEDIUMINT` | number | `1000` | `1000` |
| `BIGINT` | number | `1000000` | `1000000` |
| `FLOAT` | number | `3.14` | `3.14` |
| `DOUBLE` | number | `3.14159` | `3.14159` |
| `DECIMAL` | number | `99.99` | `99.99` |
| `NUMERIC` | number | `123.45` | `123.45` |

### String Types

| SQL Type | Lua Type | Example Input | Example Output |
|----------|----------|---------------|----------------|
| `VARCHAR(n)` | string | `'Hello'` | `"Hello"` |
| `CHAR(n)` | string | `'A'` | `"A"` |
| `TEXT` | string | `'Long description'` | `"Long description"` |
| `TINYTEXT` | string | `'Short'` | `"Short"` |
| `MEDIUMTEXT` | string | `'Medium text'` | `"Medium text"` |
| `LONGTEXT` | string | `'Very long text'` | `"Very long text"` |

### Date/Time Types

| SQL Type | Lua Type | Example Input | Example Output |
|----------|----------|---------------|----------------|
| `DATE` | string | `'2024-01-15'` | `"2024-01-15"` |
| `TIME` | string | `'12:30:00'` | `"12:30:00"` |
| `DATETIME` | string | `'2024-01-15 12:30:00'` | `"2024-01-15 12:30:00"` |
| `TIMESTAMP` | string | `'2024-01-15 12:30:00'` | `"2024-01-15 12:30:00"` |

### Boolean Types

| SQL Type | Lua Type | Example Input | Example Output |
|----------|----------|---------------|----------------|
| `BOOL` | boolean | `TRUE` | `true` |
| `BOOLEAN` | boolean | `FALSE` | `false` |

### Binary Types (Converted to String)

| SQL Type | Lua Type | Example |
|----------|----------|---------|
| `BLOB` | string | Binary data as escaped string |
| `TINYBLOB` | string | Small binary data |
| `MEDIUMBLOB` | string | Medium binary data |
| `LONGBLOB` | string | Large binary data |

## Special Value Handling

### NULL Values

- `NULL`, `null` are converted to Lua `nil`
- When a column has `NOT NULL`, the default value is used if applicable

### Escaped Characters

The converter handles common escape sequences:

| Escape Sequence | Result |
|-----------------|--------|
| `\n` | Newline character |
| `\t` | Tab character |
| `\r` | Carriage return |
| `\'` | Single quote |
| `\"` | Double quote |
| `\\` | Backslash |

### Special Characters in Strings

Strings are properly escaped for Lua output:

| Character | Lua Escape |
|-----------|------------|
| `"` | `\"` |
| `\` | `\\` |
| Newline | `\n` |
| Tab | `\t` |
| Carriage return | `\r` |

## Example SQL File Structure

A typical DAoC SQL file follows this structure:

```sql
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

CREATE TABLE IF NOT EXISTS `table_name` (
  `column1` int(11) NOT NULL,
  `column2` varchar(255) NOT NULL,
  `column3` text,
  PRIMARY KEY (`column1`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

/*!40000 ALTER TABLE `table_name` DISABLE KEYS */;
REPLACE INTO `table_name` (`column1`, `column2`, `column3`) VALUES
	(1, 'Value 1', 'Description 1'),
	(2, 'Value 2', 'Description 2');
/*!40000 ALTER TABLE `table_name` ENABLE KEYS */;
```

The converter automatically handles:
- SQL comments at the beginning (`/*! ... */`)
- Multiple `SET` statements
- `ALTER TABLE` statements (ignored)
- The data insertion statements

## Limitations

### Currently Unsupported

The following SQL features are NOT supported:

1. **Complex JOIN statements** - Only single table parsing is supported
2. **Subqueries** - Not parsed
3. **Stored procedures** - Not supported
4. **Triggers** - Not supported
5. **Views** - Not supported
6. **Transactions** - Not applicable to data extraction
7. **ALTER TABLE data modifications** - Only structure is parsed
8. **Multiple tables in single file** - Each file should contain one table

### Known Issues

1. Very large VARCHAR values (>10000 chars) may cause performance issues
2. Complex nested parentheses in VALUES may not parse correctly
3. Binary data (BLOB) is converted to escaped strings

## Tips for Best Results

1. **Use REPLACE INTO**: Preferred over INSERT for DAoC data
2. **Include column names**: Always specify columns in INSERT/REPLACE statements
3. **Single table per file**: Keep one table definition per SQL file
4. **Standard format**: Use standard DAoC database exports
5. **UTF-8 encoding**: Ensure files are UTF-8 encoded

## Error Handling

The converter provides detailed error messages for:

- Malformed CREATE TABLE statements
- Invalid column definitions
- Unparseable value tuples
- Type conversion failures
- Missing required columns

Check the debug panel in the plugin interface for detailed error information.

## Data Validation

After parsing, the converter validates:

1. Column count matches value count
2. All required columns are present
3. Values can be converted to appropriate Lua types
4. String escaping is correct

Invalid records are logged but may still be included in the output with `nil` values for problematic fields.

