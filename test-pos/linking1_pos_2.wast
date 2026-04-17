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
