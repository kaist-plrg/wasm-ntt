(module
  (type $t1 (func (param f32 f32)))
  (type $t2 (func (param $x f32) (param $y f32)))

  (func $f1 (type $t1))
  (func $f2 (type $t2))
  (table funcref (elem $f1 $f2))

  (func (export "run")
    (call_indirect (type $t1) (f32.const 1) (f32.const 2) (i32.const 1))
    (call_indirect (type $t2) (f32.const 1) (f32.const 2) (i32.const 0))
  )
)
