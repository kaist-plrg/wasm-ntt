(module $Mm
  (memory $mem0 (export "mem0") 0 0)
  (memory $mem1 (export "mem1") 1 5)
  (memory $mem2 (export "mem2") 0 0)
  
  (data (memory 1) (i32.const 10) "\00\01\02\03\04\05\06\07\08\09")

  (func (export "load") (param $a i32) (result i32)
    (i32.load8_u $mem1 (local.get 0))
  )
)

(register "Mm" $Mm)

(module $Nm
  (func $loadM (import "Mm" "load") (param i32) (result i32))
  (memory (import "Mm" "mem0") 0)

  (memory $m 1)
  (data (memory 1) (i32.const 10) "\f0\f1\f2\f3\f4\f5")

  (export "Mm.load" (func $loadM))
  (func (export "load") (param $a i32) (result i32)
    (i32.load8_u $m (local.get 0))
  )
)
