(module
  (import "spectest" "table" (table 10 funcref))
  (func $f)
  (elem (i32.const 9) $f)
  (elem (i32.const 3) $f)
  (elem (i32.const 7) $f)
  (elem (i32.const 3) $f)
  (elem (i32.const 5) $f)
)
