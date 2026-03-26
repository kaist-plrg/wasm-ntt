(assert_invalid
   (module 
     (table 1 funcref)
     (elem (global.get 0))
   )
   "unknown global 0"
)
