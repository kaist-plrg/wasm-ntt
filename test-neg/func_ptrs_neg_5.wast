(assert_invalid
  (module (table 1 funcref) (elem (nop)))
  "constant expression required"
)
