(module
  (rec (type $f1 (sub (func))) (type (struct (field (ref $f1)))))
  (rec (type $f2 (sub (func))) (type (struct (field (ref $f2)))))
  (rec (type $g (sub $f1 (func))) (type (struct)))
  (func (export "g") (type $g))
)
