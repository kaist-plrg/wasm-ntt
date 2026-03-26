(module
  (rec
    (type $t0 (func (param i32 (ref $t1))))
    (type $t1 (func (param i32 (ref $t0))))
  )
  (rec
    (type $t2 (func (param i32 (ref $t3))))
    (type $t3 (func (param i32 (ref $t2))))
  )

  (func $f0 (param $r (ref $t0))
    (call $f2 (local.get $r))
  )
  (func $f1 (param $r (ref $t1))
    (call $f3 (local.get $r))
  )
  (func $f2 (param $r (ref $t2))
    (call $f0 (local.get $r))
  )
  (func $f3 (param $r (ref $t3))
    (call $f1 (local.get $r))
  )
)
