(assert_invalid
   (module
     (func (export "test")
       (data.drop 0)))
   "unknown data segment")
