(module
  (func $f)
  (func $g)

  (table $t 10 (ref func) (ref.func $f))
  (elem (i32.const 3) $g)
)
