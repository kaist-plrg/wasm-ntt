(assert_invalid
   (module
     (global (import "test" "global-i32") i32)
     (memory 1)
     (data (global.get 1))
   )
   "unknown global 1"
)
