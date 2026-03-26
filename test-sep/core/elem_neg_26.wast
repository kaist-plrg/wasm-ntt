(assert_invalid
  (module
    (table $t 1 funcref)
    (elem $e externref (ref.null extern))
    (func (table.init $t $e (i32.const 0) (i32.const 0) (i32.const 1))))
  "type mismatch"
)
