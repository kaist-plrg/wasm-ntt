(assert_invalid
  (module (table $table-invalid 10 (ref null 1)))
  "unknown type"
)
