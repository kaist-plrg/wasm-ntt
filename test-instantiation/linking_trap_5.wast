(module $Mm
  (memory (export "mem") 1 5)
  (data (i32.const 10) "\00\01\02\03\04\05\06\07\08\09")

  (func (export "load") (param $a i32) (result i32)
    (i32.load8_u (local.get 0))
  )
)

(register "Mm" $Mm)

(module $Nm
  (func $loadM (import "Mm" "load") (param i32) (result i32))

  (memory 1)
  (data (i32.const 10) "\f0\f1\f2\f3\f4\f5")

  (export "Mm.load" (func $loadM))
  (func (export "load") (param $a i32) (result i32)
    (i32.load8_u (local.get 0))
  )
)

(assert_return (invoke $Mm "load" (i32.const 12)) (i32.const 2))

(assert_return (invoke $Nm "Mm.load" (i32.const 12)) (i32.const 2))

(assert_return (invoke $Nm "load" (i32.const 12)) (i32.const 0xf2))

(module $Om
  (memory (import "Mm" "mem") 1)
  (data (i32.const 5) "\a0\a1\a2\a3\a4\a5\a6\a7")

  (func (export "load") (param $a i32) (result i32)
    (i32.load8_u (local.get 0))
  )
)

(assert_return (invoke $Mm "load" (i32.const 12)) (i32.const 0xa7))

(assert_return (invoke $Nm "Mm.load" (i32.const 12)) (i32.const 0xa7))

(assert_return (invoke $Nm "load" (i32.const 12)) (i32.const 0xf2))

(assert_return (invoke $Om "load" (i32.const 12)) (i32.const 0xa7))

(module
  (memory (import "Mm" "mem") 0)
  (data (i32.const 0xffff) "a")
)

(assert_trap
  (module
    (memory (import "Mm" "mem") 0)
    (data (i32.const 0x10000) "a")
  )
  "out of bounds memory access"
)

(module $Pm
  (memory (import "Mm" "mem") 1 8)

  (func (export "grow") (param $a i32) (result i32)
    (memory.grow (local.get 0))
  )
)

(assert_return (invoke $Pm "grow" (i32.const 0)) (i32.const 1))

(assert_return (invoke $Pm "grow" (i32.const 2)) (i32.const 1))

(assert_return (invoke $Pm "grow" (i32.const 0)) (i32.const 3))

(assert_return (invoke $Pm "grow" (i32.const 1)) (i32.const 3))

(assert_return (invoke $Pm "grow" (i32.const 1)) (i32.const 4))

(assert_return (invoke $Pm "grow" (i32.const 0)) (i32.const 5))

(assert_return (invoke $Pm "grow" (i32.const 1)) (i32.const -1))

(assert_return (invoke $Pm "grow" (i32.const 0)) (i32.const 5))

(assert_return (invoke $Mm "load" (i32.const 0)) (i32.const 0))

(assert_trap
  (module
    ;; Note: the memory is 5 pages large by the time we get here.
    (memory (import "Mm" "mem") 1)
    (data (i32.const 0) "abc")
    (data (i32.const 327670) "zzzzzzzzzzzzzzzzzz") ;; (partially) out of bounds
  )
  "out of bounds memory access"
)
