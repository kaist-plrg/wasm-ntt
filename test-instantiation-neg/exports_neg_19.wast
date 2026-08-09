(assert_invalid
  (module (table 0 funcref) (export "a" (table 1)))
  "unknown table"
)
