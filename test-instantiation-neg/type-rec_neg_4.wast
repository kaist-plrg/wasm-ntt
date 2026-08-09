(assert_invalid
  (module
    (rec (type $f1 (func)) (type (struct)))
    (rec (type $f2 (func)) (type (struct)) (type (func)))
    (global (ref $f1) (ref.func $f))
    (func $f (type $f2))
  )
  "type mismatch"
)
