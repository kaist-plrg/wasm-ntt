(module
  (type $t (array (mut i32)))
  (func (export "array.get-null")
    (local (ref null $t)) (drop (array.get $t (local.get 0) (i32.const 0)))
  )
  (func (export "array.set-null")
    (local (ref null $t)) (array.set $t (local.get 0) (i32.const 0) (i32.const 0))
  )
)
