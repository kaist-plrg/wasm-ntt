(module $Mm
  (memory $mem0 (export "mem0") 0 0)
  (memory $mem1 (export "mem1") 5 5)
  (memory $mem2 (export "mem2") 0 0)
  
  (data (memory 1) (i32.const 10) "\00\01\02\03\04\05\06\07\08\09")

  (func (export "load") (param $a i32) (result i32)
    (i32.load8_u $mem1 (local.get 0))
  )
)

(register "Mm" $Mm)

(assert_return (invoke $Mm "load" (i32.const 0)) (i32.const 0))

(assert_trap
  (module
    ;; Note: the memory is 5 pages large by the time we get here.
    (memory (import "Mm" "mem1") 1)
    (data (i32.const 0) "abc")
    (data (i32.const 327670) "zzzzzzzzzzzzzzzzzz") ;; (partially) out of bounds
  )
  "out of bounds memory access"
)
