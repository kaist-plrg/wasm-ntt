(module
    (memory 1)

    (func $addr_limit (result i32)
      (i32.mul (memory.size) (i32.const 0x10000))
    )

    (func (export "store") (param $i i32) (param $v i32)
      (i32.store (i32.add (call $addr_limit) (local.get $i)) (local.get $v))
    )

    (func (export "load") (param $i i32) (result i32)
      (i32.load (i32.add (call $addr_limit) (local.get $i)))
    )

    (func (export "memory.grow") (param i32) (result i32)
      (memory.grow (local.get 0))
    )
)
