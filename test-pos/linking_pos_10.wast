(module $Ot
  (type (func (result i32)))

  (func $h (import "Mt" "h") (result i32))
  (table (import "Mt" "tab") 5 funcref)
  (elem (i32.const 1) $i $h)
  (func $i (result i32) (i32.const 6))

  (func (export "call") (param i32) (result i32)
    (call_indirect (type 0) (local.get 0))
  )
)
