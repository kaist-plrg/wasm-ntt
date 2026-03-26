(module
  (type (func (result i32)))
  (table $tab (import "spectest" "table") 10 20 funcref)
  (table $tab64 (import "test" "table64-10-inf") i64 10 funcref)
  (elem (table $tab) (i32.const 1) func $f $g)

  (func (export "call") (param i32) (result i32)
    (call_indirect $tab (type 0) (local.get 0))
  )
  (func $f (result i32) (i32.const 11))
  (func $g (result i32) (i32.const 22))
)
