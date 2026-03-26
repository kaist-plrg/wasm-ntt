(assert_invalid
  (module
    (type $t4 (func (result (ref null func))))
    (elem declare func $f44)
    (func $f34 (result (ref func)) (return_call_ref $t4 (ref.func $f44)))
    (func $f44 (result (ref null func)) (return_call_ref $t4 (ref.func $f44)))
  )
  "type mismatch"
)
