(module $observe_test_provider
  (func (export "func"))
  (global (export "global-i32") i32 (i32.const 0))
  (global (export "g") (mut i32) (i32.const 0))
  (global (export "global-mut-i32") (mut i32) (i32.const 0))
)
(register "test" $observe_test_provider)
