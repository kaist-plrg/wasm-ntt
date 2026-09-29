(module
  (type $arrref_mut (array (mut funcref)))

  (global $g_arrref_mut (ref $arrref_mut) (array.new_default $arrref_mut (i32.const 12)))

  (table $t 1 funcref)

  (elem $e1 func $zero $one $two $three $four $five $six $seven $eight $nine $ten $eleven)

  (func $zero (result i32) (i32.const 0))
  (func $one (result i32) (i32.const 1))
  (func $two (result i32) (i32.const 2))
  (func $three (result i32) (i32.const 3))
  (func $four (result i32) (i32.const 4))
  (func $five (result i32) (i32.const 5))
  (func $six (result i32) (i32.const 6))
  (func $seven (result i32) (i32.const 7))
  (func $eight (result i32) (i32.const 8))
  (func $nine (result i32) (i32.const 9))
  (func $ten (result i32) (i32.const 10))
  (func $eleven (result i32) (i32.const 11))

  (func (export "array_call_nth") (param $n i32) (result i32)
    (table.set $t (i32.const 0) (array.get $arrref_mut (global.get $g_arrref_mut) (local.get $n)))
    (call_indirect $t (result i32) (i32.const 0))
  )

  (func (export "array_init_elem-null")
    (array.init_elem $arrref_mut $e1 (ref.null $arrref_mut) (i32.const 0) (i32.const 0) (i32.const 0))
  )

  (func (export "array_init_elem") (param $1 i32) (param $2 i32) (param $3 i32)
    (array.init_elem $arrref_mut $e1 (global.get $g_arrref_mut) (local.get $1) (local.get $2) (local.get $3))
  )

  (func (export "drop_segs")
    (elem.drop $e1)
  )
)
