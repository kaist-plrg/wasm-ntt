(module
  (memory i64 1)
  (func
    i64.const 0
    i32.load offset=0xFFFF_FFFF_FFFF_FFFF
    drop
  )
)
