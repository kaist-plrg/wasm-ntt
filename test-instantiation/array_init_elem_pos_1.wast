(module
  (type $t_f (func))
  (type $arrref (array (ref $t_f)))
  (type $arrref_mut (array (mut funcref)))

  (global $g_arrref (ref $arrref) (array.new $arrref (ref.func $dummy) (i32.const 12)))
  (global $g_arrref_mut (ref $arrref_mut) (array.new_default $arrref_mut (i32.const 12)))

  (table $t 1 funcref)

  (elem $e1 func $dummy $dummy $dummy $dummy $dummy $dummy $dummy $dummy $dummy $dummy $dummy $dummy)

  (func $dummy
  )

  (func (export "array_call_nth") (param $1 i32)
    (table.set $t (i32.const 0) (array.get $arrref_mut (global.get $g_arrref_mut) (local.get $1)))
    (call_indirect $t (i32.const 0))
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
