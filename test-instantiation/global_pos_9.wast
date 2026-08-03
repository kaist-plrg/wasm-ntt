(module
  (global (export "g") i32 (i32.const 4))
)

(register "G")

(module
  (global $g0 (import "G" "g") i32)
  (global $g1 i32 (i32.const 8))
  (global $g2 i32 (global.get $g0))
  (global $g3 i32 (global.get $g1))

  (global $gf funcref (ref.func $f))
  (func $f)

  (table $t 10 funcref (ref.null func))
  (elem (table $t) (global.get $g2) funcref (ref.func $f))
  (elem (table $t) (global.get $g3) funcref (global.get $gf))

  (memory $m 1)
  (data (global.get $g2) "\44\44\44\44")
  (data (global.get $g3) "\88\88\88\88")

  (func (export "get-elem") (param $i i32) (result funcref)
    (table.get $t (local.get $i))
  )
  (func (export "get-data") (param $i i32) (result i32)
    (i32.load (local.get $i))
  )
)
