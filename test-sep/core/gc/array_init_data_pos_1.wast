(module
  (type $arr8 (array i8))
  (type $arr8_mut (array (mut i8)))
  (type $arr16_mut (array (mut i16)))

  (global $g_arr8 (ref $arr8) (array.new $arr8 (i32.const 10) (i32.const 12)))
  (global $g_arr8_mut (mut (ref $arr8_mut)) (array.new_default $arr8_mut (i32.const 12)))
  (global $g_arr16_mut (ref $arr16_mut) (array.new_default $arr16_mut (i32.const 6)))

  (data $d1 "abcdefghijkl")

  (func (export "array_get_nth") (param $1 i32) (result i32)
    (array.get_u $arr8_mut (global.get $g_arr8_mut) (local.get $1))
  )

  (func (export "array_get_nth_i16") (param $1 i32) (result i32)
    (array.get_u $arr16_mut (global.get $g_arr16_mut) (local.get $1))
  )

  (func (export "array_init_data-null")
    (array.init_data $arr8_mut $d1 (ref.null $arr8_mut) (i32.const 0) (i32.const 0) (i32.const 0))
  )

  (func (export "array_init_data") (param $1 i32) (param $2 i32) (param $3 i32)
    (array.init_data $arr8_mut $d1 (global.get $g_arr8_mut) (local.get $1) (local.get $2) (local.get $3))
  )

  (func (export "array_init_data_i16") (param $1 i32) (param $2 i32) (param $3 i32)
    (array.init_data $arr16_mut $d1 (global.get $g_arr16_mut) (local.get $1) (local.get $2) (local.get $3))
  )

  (func (export "drop_segs")
    (data.drop $d1)
  )
)
