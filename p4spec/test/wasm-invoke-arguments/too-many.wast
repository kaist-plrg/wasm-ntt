(module (func (export "f")))
(assert_return (invoke "f" (i32.const 0)))
