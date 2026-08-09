(assert_invalid
   (module 
     (global (import "test" "global-mut-i32") (mut i32))
     (memory 1)
     (data (global.get 0))
   )
   "constant expression required"
)
