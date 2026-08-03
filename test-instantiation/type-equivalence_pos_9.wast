(module
  (rec
    (type $t1 (func (param i32 (ref $t1))))
    (type $t2 (func (param i32 (ref $t3))))
    (type $t3 (func (param i32 (ref $t2))))
  )

  (rec
    (type $u1 (func (param i32 (ref $u1))))
    (type $u2 (func (param i32 (ref $u3))))
    (type $u3 (func (param i32 (ref $u2))))
  )

  (func $f1 (type $t1))
  (func $f2 (type $t2))
  (func $f3 (type $t3))
  (table funcref (elem $f1 $f2 $f3))

  (func (export "run")
    (call_indirect (type $t1) (i32.const 1) (ref.func $f1) (i32.const 0))
    (call_indirect (type $t2) (i32.const 1) (ref.func $f3) (i32.const 1))
    (call_indirect (type $t3) (i32.const 1) (ref.func $f2) (i32.const 2))
    (call_indirect (type $u1) (i32.const 1) (ref.func $f1) (i32.const 0))
    (call_indirect (type $u2) (i32.const 1) (ref.func $f3) (i32.const 1))
    (call_indirect (type $u3) (i32.const 1) (ref.func $f2) (i32.const 2))
  )
)
