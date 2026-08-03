(assert_trap
  (module
    (global (import "spectest" "global_i32") i32)
    (memory 0)
    (data (global.get 0) "a")
  )
  "out of bounds memory access"
)
