(module
    (memory i64 0)

    (func (export "load_at_zero") (result i32) (i32.load (i64.const 0)))
    (func (export "store_at_zero") (i32.store (i64.const 0) (i32.const 2)))

    (func (export "load_at_page_size") (result i32) (i32.load (i64.const 0x10000)))
    (func (export "store_at_page_size") (i32.store (i64.const 0x10000) (i32.const 3)))

    (func (export "grow") (param $sz i64) (result i64) (memory.grow (local.get $sz)))
    (func (export "size") (result i64) (memory.size))
)
