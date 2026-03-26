(module
  (memory 1)
  (func (export "v128.load_offset_65521")
    (drop (v128.load offset=65521 (i32.const 0)))
  )
)
