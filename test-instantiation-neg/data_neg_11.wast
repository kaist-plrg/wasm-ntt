(assert_invalid
  (module
    (global (import "test" "global-i32") i32)
    (memory 1)
    (data (offset (global.get 0) (global.get 0)))
  )
  "type mismatch"
)
