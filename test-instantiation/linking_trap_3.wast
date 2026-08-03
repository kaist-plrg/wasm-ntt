(module $Mt
  (type (func (result i32)))
  (type (func))

  (table (export "tab") 10 funcref)
  (elem (i32.const 2) $g $g $g $g)
  (func $g (result i32) (i32.const 4))
  (func (export "h") (result i32) (i32.const -4))

  (func (export "call") (param i32) (result i32)
    (call_indirect (type 0) (local.get 0))
  )
)

(register "Mt" $Mt)

(module $Nt
  (type (func))
  (type (func (result i32)))

  (func $f (import "Mt" "call") (param i32) (result i32))
  (func $h (import "Mt" "h") (result i32))

  (table funcref (elem $g $g $g $h $f))
  (func $g (result i32) (i32.const 5))

  (export "Mt.call" (func $f))
  (func (export "call Mt.call") (param i32) (result i32)
    (call $f (local.get 0))
  )
  (func (export "call") (param i32) (result i32)
    (call_indirect (type 1) (local.get 0))
  )
)

(assert_return (invoke $Mt "call" (i32.const 2)) (i32.const 4))

(assert_return (invoke $Nt "Mt.call" (i32.const 2)) (i32.const 4))

(assert_return (invoke $Nt "call" (i32.const 2)) (i32.const 5))

(assert_return (invoke $Nt "call Mt.call" (i32.const 2)) (i32.const 4))

(assert_return (invoke $Nt "call" (i32.const 1)) (i32.const 5))

(assert_return (invoke $Nt "call" (i32.const 0)) (i32.const 5))

(assert_return (invoke $Nt "call" (i32.const 3)) (i32.const -4))

(module $Ot
  (type (func (result i32)))

  (func $h (import "Mt" "h") (result i32))
  (table (import "Mt" "tab") 5 funcref)
  (elem (i32.const 1) $i $h)
  (func $i (result i32) (i32.const 6))

  (func (export "call") (param i32) (result i32)
    (call_indirect (type 0) (local.get 0))
  )
)

(assert_return (invoke $Mt "call" (i32.const 3)) (i32.const 4))

(assert_return (invoke $Nt "Mt.call" (i32.const 3)) (i32.const 4))

(assert_return (invoke $Nt "call Mt.call" (i32.const 3)) (i32.const 4))

(assert_return (invoke $Ot "call" (i32.const 3)) (i32.const 4))

(assert_return (invoke $Mt "call" (i32.const 2)) (i32.const -4))

(assert_return (invoke $Nt "Mt.call" (i32.const 2)) (i32.const -4))

(assert_return (invoke $Nt "call" (i32.const 2)) (i32.const 5))

(assert_return (invoke $Nt "call Mt.call" (i32.const 2)) (i32.const -4))

(assert_return (invoke $Ot "call" (i32.const 2)) (i32.const -4))

(assert_return (invoke $Mt "call" (i32.const 1)) (i32.const 6))

(assert_return (invoke $Nt "Mt.call" (i32.const 1)) (i32.const 6))

(assert_return (invoke $Nt "call" (i32.const 1)) (i32.const 5))

(assert_return (invoke $Nt "call Mt.call" (i32.const 1)) (i32.const 6))

(assert_return (invoke $Ot "call" (i32.const 1)) (i32.const 6))

(assert_return (invoke $Nt "call" (i32.const 0)) (i32.const 5))

(module
  (table (import "Mt" "tab") 0 funcref)
  (elem (i32.const 9) $f)
  (func $f)
)

(assert_trap
  (module
    (table (import "Mt" "tab") 0 funcref)
    (elem (i32.const 10) $f)
    (func $f)
  )
  "out of bounds table access"
)

(assert_trap
  (module
    (table (import "Mt" "tab") 10 funcref)
    (func $f (result i32) (i32.const 0))
    (elem (i32.const 7) $f)
    (elem (i32.const 8) $f $f $f $f $f)  ;; (partially) out of bounds
  )
  "out of bounds table access"
)

(assert_return (invoke $Mt "call" (i32.const 7)) (i32.const 0))

(assert_trap
  (module
    (table (import "Mt" "tab") 10 funcref)
    (func $f (result i32) (i32.const 0))
    (elem (i32.const 7) $f)
    (memory 1)
    (data (i32.const 0x10000) "d")  ;; out of bounds
  )
  "out of bounds memory access"
)
