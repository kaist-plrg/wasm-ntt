(module
  (memory $mem1 (import "M" "mem") 2)
  (memory $mem2 3)

  (data (memory $mem1) (i32.const 20) "\01\02\03\04\05")
  (data (memory $mem2) (i32.const 50) "\0A\0B\0C\0D\0E")

  (func (export "read1") (param i32) (result i32)
    (i32.load8_u $mem1 (local.get 0))
  )
  (func (export "read2") (param i32) (result i32)
    (i32.load8_u $mem2 (local.get 0))
  )
)
