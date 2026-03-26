(assert_invalid
  (module
    (func $f)
    (table $t 1 externref)
    (elem $e funcref (ref.func $f))
    (func (table.init $t $e (i32.const 0) (i32.const 0) (i32.const 1))))
  "type mismatch"
)
