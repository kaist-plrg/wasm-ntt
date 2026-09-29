(module
  (type $arr (array (mut arrayref)))

  (table $table 2 arrayref)
  (elem $elem arrayref (item (array.new_default $arr (i32.const 0))))

  (func (export "run") (result i32)
    (table.init $table $elem (i32.const 0) (i32.const 0) (i32.const 1))
    (table.init $table $elem (i32.const 1) (i32.const 0) (i32.const 1))
    (ref.eq (table.get $table (i32.const 0))
            (table.get $table (i32.const 1)))
  )
)
