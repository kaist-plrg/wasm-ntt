(module
  (rec (type $t1 (func (param i32 (ref $t1)))))
  (func (export "f") (param (ref $t1)))
)
