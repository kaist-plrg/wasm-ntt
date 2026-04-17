(module
  (type $s (sub (struct)))
  (type $s' (sub $s (struct)))

  (type $f1 (sub (func (param (ref $s')) (result anyref))))
  (type $f2 (sub $f1 (func (param (ref $s)) (result (ref any)))))
  (type $f3 (sub $f2 (func (param (ref null $s)) (result (ref $s)))))
  (type $f4 (sub $f3 (func (param (ref null struct)) (result (ref $s')))))
)
