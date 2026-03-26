(module
  (memory $mem0 0)
  (memory $mem1 1)
  (memory $mem2 0)
  (data $p "x")
  (data $a (memory 1) (i32.const 0) "x")

  (func (export "drop_passive") (data.drop $p))
  (func (export "init_passive") (param $len i32)
    (memory.init $mem1 $p (i32.const 0) (i32.const 0) (local.get $len)))

  (func (export "drop_active") (data.drop $a))
  (func (export "init_active") (param $len i32)
    (memory.init $mem1 $a (i32.const 0) (i32.const 0) (local.get $len)))
)
