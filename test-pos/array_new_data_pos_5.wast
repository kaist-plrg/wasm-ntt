(module
  (type $arr (array (mut i16)))

  (data $d "\00\11\22")

  (func (export "array-new-data-unaligned") (result i32)
    (array.get_u $arr
                 (array.new_data $arr $d (i32.const 1) (i32.const 1))
                 (i32.const 0))
  )
)
