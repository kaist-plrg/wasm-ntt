(module
  (import "spectest" "print_i32" (func $imported_print (param i32)))
  (func (export "print_i32") (param $i i32)
    (call $imported_print (local.get $i))
  )
)
