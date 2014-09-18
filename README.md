# format-helper



PowerShell module for generating format data from object types.

# Example

```powershell

import-module FormatHelper
get-item path/to/item | convertto-formatdata | out-file item-formats.ps1xml
```