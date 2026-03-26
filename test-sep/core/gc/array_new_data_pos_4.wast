(module
  (type $arr (array (mut i32)))

  (data $d "\aa\bb\cc\dd")

  (func (export "array-new-data-little-endian") (result i32)
    (array.get $arr
               (array.new_data $arr $d (i32.const 0) (i32.const 1))
               (i32.const 0))
  )
)
