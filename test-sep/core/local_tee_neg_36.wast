(assert_invalid
  (module
    (type $t (func))
    (func $f (param (ref null $t)))
    (func
      (local $x funcref)
      (ref.null $t)
      (local.tee $x)  ;; leaves only a funcref on the stack
      (call $f)
    )
  )
  "type mismatch"
)
