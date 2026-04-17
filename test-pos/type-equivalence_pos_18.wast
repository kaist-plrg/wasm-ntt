(module
  (rec
    (type $t1 (func (param i32 (ref $t3))))
    (type $t2 (func (param i32 (ref $t1))))
    (type $t3 (func (param i32 (ref $t2))))
  )
  (func (export "f1") (param (ref $t1)))
  (func (export "f2") (param (ref $t2)))
  (func (export "f3") (param (ref $t3)))
)
