(module
  (global $g i32 (i32.const 0))
  (table 1 funcref) (elem (global.get $g) $f) (func $f)
)
