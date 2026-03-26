(assert_invalid
  (module
    (rec (type $f11 (sub (func))) (type $f12 (sub $f11 (func))))
    (rec (type $f21 (sub (func))) (type $f22 (sub $f11 (func))))
    (func $f (type $f21))
    (global (ref $f11) (ref.func $f))
  )
  "type mismatch"
)
