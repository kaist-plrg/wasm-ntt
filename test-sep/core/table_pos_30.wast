(module
  (global $g (import "M" "g") (ref $dummy))

  (type $dummy (func))
  (func $dummy)

  (table $t1 10 funcref)
  (table $t2 10 funcref (ref.func $dummy))
  (table $t3 10 (ref $dummy) (ref.func $dummy))
  (table $t4 10 funcref (global.get $g))
  (table $t5 10 (ref $dummy) (global.get $g))

  (func (export "get1") (result funcref) (table.get $t1 (i32.const 1)))
  (func (export "get2") (result funcref) (table.get $t2 (i32.const 4)))
  (func (export "get3") (result funcref) (table.get $t3 (i32.const 7)))
  (func (export "get4") (result funcref) (table.get $t4 (i32.const 8)))
  (func (export "get5") (result funcref) (table.get $t5 (i32.const 9)))
)
