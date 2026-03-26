(module $Mf
  (func (export "call") (result i32) (call $g))
  (func $g (result i32) (i32.const 2))
)
