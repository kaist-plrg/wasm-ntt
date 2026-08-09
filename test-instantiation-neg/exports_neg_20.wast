(assert_invalid
  (module  (import "spectest" "table" (table 10 20 funcref)) (export "a" (table 1)))
  "unknown table"
)
