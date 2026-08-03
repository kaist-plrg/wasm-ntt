(assert_trap
  (module
    (global (import "spectest" "global_i32") i32)
    (memory 3)
    (memory 0)
    (memory 3)
    (data (memory 1) (global.get 0) "a")
  )
  "out of bounds memory access"
)
