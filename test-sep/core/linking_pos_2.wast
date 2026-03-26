(module $Nf
  (func $f (import "Mf" "call") (result i32))
  (export "Mf.call" (func $f))
  (func (export "call Mf.call") (result i32) (call $f))
  (func (export "call") (result i32) (call $g))
  (func $g (result i32) (i32.const 3))
)
