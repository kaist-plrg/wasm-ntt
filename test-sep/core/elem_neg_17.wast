(assert_invalid
   (module 
     (global (import "test" "global-mut-i32") (mut i32))
     (table 1 funcref)
     (elem (global.get 0))
   )
   "constant expression required"
)
