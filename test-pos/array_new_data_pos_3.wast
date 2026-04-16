(module
  (type $arr (array (mut i8)))

  (data $d "\aa\bb\cc\dd")

  (func (export "array-new-data-contents") (result i32 i32)
    (local (ref $arr))
    (local.set 0 (array.new_data $arr $d (i32.const 1) (i32.const 2)))
    (array.get_u $arr (local.get 0) (i32.const 0))
    (array.get_u $arr (local.get 0) (i32.const 1))
  )
)
