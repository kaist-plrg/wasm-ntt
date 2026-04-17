(module
  (rec (type $f1 (sub (func))) (type (struct (field (ref $f1)))))
  (rec (type $f2 (sub (func))) (type (struct (field (ref $f2)))))
  (rec (type $g (sub $f1 (func))) (type (struct)))
  (func $g (type $g)) (elem declare func $g)
  (func (export "run") (result i32)
    (ref.test (ref $f1) (ref.func $g))
  )
)
