(module
    (memory 0)
    (memory 0)
    (memory $m 1)

    (func $addr_limit (result i32)
      (i32.mul (memory.size $m) (i32.const 0x10000))
    )

    (func (export "store") (param $i i32) (param $v i32)
      (i32.store $m (i32.add (call $addr_limit) (local.get $i)) (local.get $v))
    )

    (func (export "load") (param $i i32) (result i32)
      (i32.load $m (i32.add (call $addr_limit) (local.get $i)))
    )

    (func (export "memory.grow") (param i32) (result i32)
      (memory.grow $m (local.get 0))
    )
)
