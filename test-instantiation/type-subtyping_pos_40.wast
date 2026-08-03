(module
  (rec (type $f11 (sub (func (result (ref func))))) (type $f12 (sub $f11 (func (result (ref $f11))))))
  (rec (type $f21 (sub (func (result (ref func))))) (type $f22 (sub $f21 (func (result (ref $f21))))))
  (func (export "f11") (type $f11) (unreachable))
  (func (export "f12") (type $f12) (unreachable))
)

(register "M8")

(module
  (rec (type $f11 (sub (func (result (ref func))))) (type $f12 (sub $f11 (func (result (ref $f11))))))
  (rec (type $f21 (sub (func (result (ref func))))) (type $f22 (sub $f21 (func (result (ref $f21))))))
  (func (import "M8" "f11") (type $f11))
  (func (import "M8" "f11") (type $f21))
  (func (import "M8" "f12") (type $f12))
  (func (import "M8" "f12") (type $f22))
)
