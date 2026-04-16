(module
  (memory (export "memory") 1 1)

  ;; These should not change the behavior of memory accesses.
  (global (export "__data_end") i32 (i32.const 10000))
  (global (export "__stack_top") i32 (i32.const 10000))
  (global (export "__heap_base") i32 (i32.const 10000))

  (func (export "load") (param i32) (result i32)
    (i32.load8_u (local.get 0))
  )
)
