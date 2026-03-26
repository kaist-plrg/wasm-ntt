(assert_invalid
  (module
    (type $t (func))
    (type $t3 (func (result (ref func))))
    (elem declare func $f33)
    (func $f13 (result (ref $t)) (return_call_ref $t3 (ref.func $f33)))
    (func $f33 (result (ref func)) (return_call_ref $t3 (ref.func $f33)))
  )
  "type mismatch"
)
