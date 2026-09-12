(assert_invalid
   (module
     (global (import "test" "global-i32") i32)
     (table 1 funcref)
     (elem (global.get 1))
   )
   "unknown global 1"
)
