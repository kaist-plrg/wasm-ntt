(module
  (import "spectest" "print_i32" (func $imported_print (param i32)))
  (func (export "print_i32") (param $i i32) (param $j i32) (result i32)
    (i32.add (local.get $i) (local.get $j))
  )
)
