(module
  (memory 1)
  (data (i32.const 0) "\00\01\02\03\04\05\06\07\08\09\0a\0b\0c\0d\0e\0f\00\01\02\03")
  (func (export "v128.load") (result v128)
    (v128.load (i32.const 0))
  )
)
