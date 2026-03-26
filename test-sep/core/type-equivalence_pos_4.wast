(module
  (type $t1 (func (param i32 (ref $t1))))
  (type $t2 (func (param i32 (ref $t2))))

  (func $f1 (param $r (ref $t1)) (call $f2 (local.get $r)))
  (func $f2 (param $r (ref $t2)) (call $f1 (local.get $r)))
)
