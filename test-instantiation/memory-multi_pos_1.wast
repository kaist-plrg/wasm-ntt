(module
  (memory $mem1 1)
  (memory $mem2 1)

  (func (export "init1") (result i32)
    (memory.init $mem1 $d (i32.const 1) (i32.const 0) (i32.const 4))
    (i32.load $mem1 (i32.const 1))
  )

  (func (export "init2") (result i32)
    (memory.init $mem2 $d (i32.const 1) (i32.const 4) (i32.const 4))
    (i32.load $mem2 (i32.const 1))
  )

  (data $d "\01\00\00\00" "\02\00\00\00")
)
