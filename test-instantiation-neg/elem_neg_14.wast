(assert_invalid
  (module
    (global $g (import "test" "g") (mut i32))
    (table 1 funcref)
    (elem (global.get $g))
  )
  "constant expression required"
)
