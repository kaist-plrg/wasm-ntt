(module
  (type $t0 (sub (func (result (ref null func)))))
  (rec (type $t1 (sub $t0 (func (result (ref null $t1))))))
  (rec (type $t2 (sub $t1 (func (result (ref null $t2))))))

  (func (export "f0") (type $t0) (ref.null func))
  (func (export "f1") (type $t1) (ref.null $t1))
  (func (export "f2") (type $t2) (ref.null $t2))
)

(register "M")

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
