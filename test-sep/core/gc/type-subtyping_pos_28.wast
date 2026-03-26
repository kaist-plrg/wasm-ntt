(module
  (type $t0 (sub (func (result (ref null func)))))
  (rec (type $t1 (sub $t0 (func (result (ref null $t1))))))
  (rec (type $t2 (sub $t1 (func (result (ref null $t2))))))

  (func (import "M" "f0") (type $t0))
  (func (import "M" "f1") (type $t0))
  (func (import "M" "f1") (type $t1))
  (func (import "M" "f2") (type $t0))
  (func (import "M" "f2") (type $t1))
  (func (import "M" "f2") (type $t2))
)
