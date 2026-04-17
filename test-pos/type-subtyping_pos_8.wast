(module
  (rec
    (type $t1 (sub (func (result i32 (ref $u1)))))
    (type $u1 (sub (func (result f32 (ref $t1)))))
  )

  (rec
    (type $t2 (sub $t1 (func (result i32 (ref $u3)))))
    (type $u2 (sub $u1 (func (result f32 (ref $t3)))))
    (type $t3 (sub $t1 (func (result i32 (ref $u2)))))
    (type $u3 (sub $u1 (func (result f32 (ref $t2)))))
  )

  (func $f1 (param $r (ref $t1))
    (call $f1 (local.get $r))
  )
  (func $f2 (param $r (ref $t2))
    (call $f1 (local.get $r))
    (call $f2 (local.get $r))
  )
  (func $f3 (param $r (ref $t3))
    (call $f1 (local.get $r))
    (call $f3 (local.get $r))
  )
)
