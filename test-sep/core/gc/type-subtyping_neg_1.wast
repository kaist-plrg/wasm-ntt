(assert_invalid
  (module
    (rec (type $f1 (sub (func))) (type (struct (field (ref $f1)))))
    (rec (type $f2 (sub (func))) (type (struct (field (ref $f1)))))
    (rec (type $g1 (sub $f1 (func))) (type (struct)))
    (rec (type $g2 (sub $f2 (func))) (type (struct)))
    (func $g (type $g2))
    (global (ref $g1) (ref.func $g))
  )
  "type mismatch"
)
