(module
  (rec (type $f1 (func)) (type (struct (field (ref $f1)))))
  (rec (type $f2 (func)) (type (struct (field (ref $f2)))))
  (rec
    (type $g1 (func))
    (type (struct (field (ref $f1) (ref $f1) (ref $f2) (ref $f2) (ref $g1))))
  )
  (rec
    (type $g2 (func))
    (type (struct (field (ref $f1) (ref $f2) (ref $f1) (ref $f2) (ref $g2))))
  )
  (func $g (type $g2))
  (global (ref $g1) (ref.func $g))
)
