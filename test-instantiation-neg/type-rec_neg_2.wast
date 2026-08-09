(assert_invalid
  (module
    (rec (type $f0 (func)) (type (struct (field (ref $f0)))))
    (rec (type $f1 (func)) (type (struct (field (ref $f0)))))
    (rec (type $f2 (func)) (type (struct (field (ref $f1)))))
    (func $f (type $f2))
    (global (ref $f1) (ref.func $f))
  )
  "type mismatch"
)
