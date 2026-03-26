(assert_invalid
  (module
    (type $t (func))
    (type $t2 (func (result (ref null $t))))
    (elem declare func $f22)
    (func $f12 (result (ref $t)) (return_call_ref $t2 (ref.func $f22)))
    (func $f22 (result (ref null $t)) (return_call_ref $t2 (ref.func $f22)))
  )
  "type mismatch"
)
