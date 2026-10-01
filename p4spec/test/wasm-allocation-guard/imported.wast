(module (import "spectest" "memory" (memory 2000)) (import "spectest" "table" (table 10000 funcref)) (func (export "f")))
(invoke "f")
