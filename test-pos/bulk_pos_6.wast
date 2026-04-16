(module
  (memory 1)
  (data $p "x")
  (data $a (memory 0) (i32.const 0) "x")

  (func (export "drop_passive") (data.drop $p))
  (func (export "init_passive") (param $len i32)
    (memory.init $p (i32.const 0) (i32.const 0) (local.get $len)))

  (func (export "drop_active") (data.drop $a))
  (func (export "init_active") (param $len i32)
    (memory.init $a (i32.const 0) (i32.const 0) (local.get $len)))
)
