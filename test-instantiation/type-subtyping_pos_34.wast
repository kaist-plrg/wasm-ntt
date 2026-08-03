(module
  (rec (type $f1 (sub (func))) (type (struct (field (ref $f1)))))
  (rec (type $f2 (sub (func))) (type (struct (field (ref $f1)))))
  (rec (type $g2 (sub $f2 (func))) (type (struct)))
  (func (export "g") (type $g2))
)
