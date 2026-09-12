(assert_invalid
  (module
    (func $f (result f64) (f64.const 0))  ;; adds implicit type definition
    (func $g (param i32))                 ;; reuses explicit type definition
    (func $h (result f64) (f64.const 1))  ;; reuses implicit type definition
    (type $t (func (param i32)))

    (func (type 2))  ;; does not exist
  )
  "unknown type"
)
