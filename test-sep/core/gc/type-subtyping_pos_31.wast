(module
  (rec (type $f1 (sub (func))) (type (struct (field (ref $f1)))))
  (rec (type $g1 (sub $f1 (func))) (type (struct)))
  (func (import "M3" "g") (type $g1))
)
