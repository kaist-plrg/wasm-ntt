(module
  (rec (type $f11 (sub (func (result (ref func))))) (type $f12 (sub $f11 (func (result (ref $f11))))))
  (rec (type $f21 (sub (func (result (ref func))))) (type $f22 (sub $f21 (func (result (ref $f21))))))
  (rec (type $g11 (sub $f11 (func (result (ref func))))) (type $g12 (sub $g11 (func (result (ref $g11))))))
  (rec (type $g21 (sub $f21 (func (result (ref func))))) (type $g22 (sub $g21 (func (result (ref $g21))))))
  (func (export "g11") (type $g11) (unreachable))
  (func (export "g12") (type $g12) (unreachable))
)
