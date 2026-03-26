(module
  (memory $mem1 1)
  (memory $mem2 1)

  (func (export "fill1") (result i32)
    (memory.fill $mem1 (i32.const 1) (i32.const 0x01) (i32.const 4))
    (i32.load $mem1 (i32.const 1))
  )

  (func (export "fill2") (result i32)
    (memory.fill $mem2 (i32.const 1) (i32.const 0x02) (i32.const 2))
    (i32.load $mem2 (i32.const 1))
  )
)
