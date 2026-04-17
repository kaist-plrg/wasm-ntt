(module
  (table $t 0x10 funcref)
  (elem declare func $f)
  (func $f (export "grow") (result i32)
    (table.grow $t (ref.func $f) (i32.const 0xffff_fff0))
  )
)
