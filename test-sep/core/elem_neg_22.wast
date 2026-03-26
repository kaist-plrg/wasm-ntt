(assert_invalid
  (module
    (table 1 funcref)
    (elem (i32.const 0) funcref (item (call $f)))
    (func $f (result funcref) (ref.null func))
  )
  "constant expression required"
)
