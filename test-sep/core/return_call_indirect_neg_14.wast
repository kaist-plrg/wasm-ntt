(assert_invalid
  (module
    (table 0 funcref)
    (func $unbound-type (return_call_indirect (type 1) (i32.const 0)))
  )
  "unknown type"
)
