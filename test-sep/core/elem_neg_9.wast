(assert_invalid
  (module
    (global (import "test" "global-i32") i32)
    (table 1 funcref)
    (elem (offset (global.get 0) (i32.const 0)))
  )
  "type mismatch"
)
