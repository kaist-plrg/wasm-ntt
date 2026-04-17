(module
  (rec (type $f01 (sub (func))) (type $f02 (sub $f01 (func))))
  (rec (type $f11 (sub (func))) (type $f12 (sub $f01 (func))))
  (rec (type $f21 (sub (func))) (type $f22 (sub $f11 (func))))
  (func (export "f") (type $f21))
)
