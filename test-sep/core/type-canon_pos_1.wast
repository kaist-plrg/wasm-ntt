(module
  (rec
    (type $t1 (func (param i32 (ref $t3))))
    (type $t2 (func (param i32 (ref $t1))))
    (type $t3 (func (param i32 (ref $t2))))
  )
)
