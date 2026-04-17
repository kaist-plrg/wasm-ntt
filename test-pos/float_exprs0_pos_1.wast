(module
  (memory 0 0)
  (memory $m 1 1)
  (memory 0 0)
  (func (export "init") (param $i i32) (param $x f64)
    (f64.store $m (local.get $i) (local.get $x)))

  (func (export "run") (param $n i32) (param $z f64)
    (local $i i32)
    (block $exit
      (loop $cont
        (f64.store $m
          (local.get $i)
          (f64.div (f64.load $m (local.get $i)) (local.get $z))
        )
        (local.set $i (i32.add (local.get $i) (i32.const 8)))
        (br_if $cont (i32.lt_u (local.get $i) (local.get $n)))
      )
    )
  )

  (func (export "check") (param $i i32) (result f64) (f64.load $m (local.get $i)))
)
