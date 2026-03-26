(module
  (memory 1)
  (func (export "v128.store_offset_65521")
    (v128.store offset=65521 (i32.const 0) (v128.const i32x4 0 0 0 0))
  )
)
