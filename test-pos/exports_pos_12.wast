(module $Func
  (export "e" (func $f))
  (func $f (param $n i32) (result i32)
    (return (i32.add (local.get $n) (i32.const 1)))
  )
)
