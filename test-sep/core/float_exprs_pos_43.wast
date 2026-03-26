(module
  (memory 1 1)
  (func (export "init") (param $i i32) (param $x f32) (f32.store (local.get $i) (local.get $x)))

  (func (export "run") (param $n i32) (param $z f32)
    (local $i i32)
    (block $exit
      (loop $cont
        (f32.store
          (local.get $i)
          (f32.div (f32.load (local.get $i)) (local.get $z))
        )
        (local.set $i (i32.add (local.get $i) (i32.const 4)))
        (br_if $cont (i32.lt_u (local.get $i) (local.get $n)))
      )
    )
  )

  (func (export "check") (param $i i32) (result f32) (f32.load (local.get $i)))
)
