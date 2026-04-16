(module
  (rec
    (type $t1 (func (param i32 (ref $u1))))
    (type $u1 (func (param f32 (ref $t1))))
  )

  (rec
    (type $t2 (func (param i32 (ref $u3))))
    (type $u2 (func (param f32 (ref $t3))))
    (type $t3 (func (param i32 (ref $u2))))
    (type $u3 (func (param f32 (ref $t2))))
  )

  (func (export "f1") (param (ref $t1)))
  (func (export "f2") (param (ref $t2)))
  (func (export "f3") (param (ref $t3)))
)
