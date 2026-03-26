(assert_invalid
  (module
    (rec (type $f1 (func)) (type (struct)))
    (rec (type (struct)) (type $f2 (func)))
    (global (ref $f1) (ref.func $f))
    (func $f (type $f2))
  )
  "type mismatch"
)
