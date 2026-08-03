(module
  (rec (type $f1 (sub (func))) (type $s1 (sub (struct (field (ref $f1))))))
  (rec (type $f2 (sub (func))) (type $s2 (sub (struct (field (ref $f2))))))
  (rec
    (type $g1 (sub $f1 (func)))
    (type (sub $s1 (struct (field (ref $f1) (ref $f1) (ref $f2) (ref $f2) (ref $g1)))))
  )
  (rec
    (type $g2 (sub $f2 (func)))
    (type (sub $s2 (struct (field (ref $f1) (ref $f2) (ref $f1) (ref $f2) (ref $g2)))))
  )
  (func $g (type $g2)) (elem declare func $g)
  (func (export "run") (result i32)
    (ref.test (ref $g1) (ref.func $g))
  )
)
