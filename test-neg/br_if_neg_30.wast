(assert_invalid
  (module
    (type $t (func))
    (func $f (param (ref null $t)) (result funcref) (local.get 0))
    (func (result funcref)
      (ref.null $t)
      (i32.const 0)
      (br_if 0)  ;; only leaves funcref on the stack
      (call $f)
    )
  )
  "type mismatch"
)
