(assert_invalid
   (module 
     (memory 1)
     (data (global.get 0))
   )
   "unknown global 0"
)
