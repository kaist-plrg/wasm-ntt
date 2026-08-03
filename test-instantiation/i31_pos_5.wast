(module $env
  (global (export "g") i32 (i32.const 42))
)

(register "env")

(module $i31ref_of_global_table_initializer
  (global $g (import "env" "g") i32)
  (table $t 3 3 (ref i31) (ref.i31 (global.get $g)))
  (func (export "get") (param i32) (result i32)
    (i31.get_u (local.get 0) (table.get $t))
  )
)

(assert_return (invoke "get" (i32.const 0)) (i32.const 42))

(assert_return (invoke "get" (i32.const 1)) (i32.const 42))

(assert_return (invoke "get" (i32.const 2)) (i32.const 42))

(module $i31ref_of_global_global_initializer
  (global $g0 (import "env" "g") i32)
  (global $g1 i31ref (ref.i31 (global.get $g0)))
  (func (export "get") (result i32)
    (i31.get_u (global.get $g1))
  )
)
