(module $module3
  (type $out-i32 (func (result i32)))
  (import "module1" "shared-table" (table 10 funcref))
  (elem (i32.const 8) $const-i32-e)
  (elem (i32.const 9) $const-i32-f)
  (func $const-i32-e (type $out-i32) (i32.const 69))
  (func $const-i32-f (type $out-i32) (i32.const 70))
)
