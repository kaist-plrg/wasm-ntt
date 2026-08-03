(assert_trap
  (module
    (import "spectest" "table" (table 10 funcref))
    (func $f)
    (elem (i32.const -10) $f)
  )
  "out of bounds table access"
)
