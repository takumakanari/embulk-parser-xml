# XML parser plugin for Embulk

Parser plugin for [Embulk](https://github.com/embulk/embulk).

Read data from input as xml and fetch each entries to output.

## Overview

* **Plugin type**: parser
* **Load all or nothing**: yes
* **Resume supported**: no


## Configuration

```yaml
parser:
  type: xml
  root: data/students/student
  schema:
    - {name: name, type: string}
    - {name: age, type: long}
```

- **type**: specify this plugin as `xml` .
- **root**: root property to start fetching each entries, specify in *path/to/node* style, required.
- **schema**: specify the attribute of table and data type, required.

If you need to parse column as timestamp type, *schema* supports 2 optional parameters:

```yaml
schema:
  - {name: timestamp_column, type: timestamp, format: "%Y-%m-%d", timezone: "+0000"}
```
- **format**: timestamp format to parse, required.
- **timezone**: timestamp will be parsing in this timezone, `"+0900"` is used by default.

Then you can fetch entries from the following xml:

```xml
<data>
  <result>true</result>
  <students>
    <student>
      <name>John</name>
      <age>10</age>
    </student>
    <student>
      <name>Paul</name>
      <age>16</age>
    </student>
    <student>
      <name>George</name>
      <age>17</age>
    </student>
    <student>
      <name>Ringo</name>
      <age>18</age>
    </student>
  </students>
</data>
```