(module
  (import "module4" "f" (global funcref))
  (type $out-i32 (func (result i32)))
  (table 10 funcref)
  (elem (offset (i32.const 0)) funcref (global.get 0))
  (func (export "call_imported_elem") (type $out-i32)
    (call_indirect (type $out-i32) (i32.const 0))
  )
)
