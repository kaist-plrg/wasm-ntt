(module definition $M
  (global (export "glob") (mut i32) (i32.const 0))
  (table (export "tab") 10 funcref (ref.null func))
  (memory (export "mem") 1)
  (tag (export "tag"))
)

(module instance $I2 $M)
