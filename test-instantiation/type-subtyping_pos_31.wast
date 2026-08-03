(module
  (rec (type $f2 (sub (func))) (type (struct (field (ref $f2)))))
  (rec (type $g2 (sub $f2 (func))) (type (struct)))
  (func (export "g") (type $g2))
)

(register "M3")

(module
  (rec (type $f1 (sub (func))) (type (struct (field (ref $f1)))))
  (rec (type $g1 (sub $f1 (func))) (type (struct)))
  (func (import "M3" "g") (type $g1))
)
