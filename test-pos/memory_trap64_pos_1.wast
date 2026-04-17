(module
    (memory i64 1)

    (func $addr_limit (result i64)
      (i64.mul (memory.size) (i64.const 0x10000))
    )

    (func (export "store") (param $i i64) (param $v i32)
      (i32.store (i64.add (call $addr_limit) (local.get $i)) (local.get $v))
    )

    (func (export "load") (param $i i64) (result i32)
      (i32.load (i64.add (call $addr_limit) (local.get $i)))
    )

    (func (export "memory.grow") (param i64) (result i64)
      (memory.grow (local.get 0))
    )
)
