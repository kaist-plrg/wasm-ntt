(module
  (rec (type $f1 (sub (func))) (type $s1 (sub (struct (field (ref $f1))))))
  (rec (type $f2 (sub (func))) (type $s2 (sub (struct (field (ref $f2))))))
  (rec
    (type $g1 (sub $f1 (func)))
    (type (sub $s1 (struct (field (ref $f1) (ref $f1) (ref $f2) (ref $f2) (ref $g1)))))
  )
  (rec (type $h (sub $g1 (func))) (type (struct)))
  (func (import "M7" "h") (type $f1))
  (func (import "M7" "h") (type $g1))
)
