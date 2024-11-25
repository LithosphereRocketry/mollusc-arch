Memory map

| Addr       | Size       | Cached | Transfer width | Function       | Notes                 |
| ---------- | ---------- | ------ | -------------- | -------------- | --------------------- |
| 0x00000000 | 0x00000800 | yes    | 32b            | Boot ROM       |                       |
| 0x00008000 | 0x00000800 | yes    | 32b            | Boot scratch   |                       |
| 0x00010000 | 0x00001000 | no     | 32b            | DRAM config    |                       |
| 0x01000000 | 0x00000004 | no     | 32b            | LED controller |                       |
| 0x01000008 | 0x00000008 | no     | 32b            | USB COM port   |                       |
| 0x01008000 | 0x00008000 | no     | 32b            | Video buffer   | Only first 20KB valid |
| 0xF8000000 | 0x08000000 | yes    | 128b           | DRAM bus       |                       |