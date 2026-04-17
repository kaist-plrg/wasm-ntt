(module
  (table 10 funcref)
  (elem $e (i32.const 0) func $f)
  (func $f)
  (func (export "init")
    (table.init $e (i32.const 0) (i32.const 0) (i32.const 1))
  )
)
