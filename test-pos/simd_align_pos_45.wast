(module
  (memory 1 1)
  (func (export "v128.load align=16") (param $address i32) (result v128)
    (v128.load align=16 (local.get $address))
  )
  (func (export "v128.store align=16") (param $address i32) (param $value v128)
    (v128.store align=16 (local.get $address) (local.get $value))
  )
)
