(module $module2
  (type $out-i32 (func (result i32)))
  (import "module1" "shared-table" (table 10 funcref))
  (elem (i32.const 7) $const-i32-c)
  (elem (i32.const 8) $const-i32-d)
  (func $const-i32-c (type $out-i32) (i32.const 67))
  (func $const-i32-d (type $out-i32) (i32.const 68))
)
