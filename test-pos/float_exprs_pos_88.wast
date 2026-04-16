(module
  (func (export "f32.epsilon") (result f32)
    (local $x f32)
    (local $result f32)
    (local.set $x (f32.const 1))
    (loop $loop
      (br_if $loop
        (f32.gt
          (f32.add
            (local.tee $x
              (f32.mul
                (local.tee $result (local.get $x))
                (f32.const 0.5)
              )
            )
            (f32.const 1)
          )
          (f32.const 1)
        )
      )
    )
    (local.get $result)
  )

  (func (export "f64.epsilon") (result f64)
    (local $x f64)
    (local $result f64)
    (local.set $x (f64.const 1))
    (loop $loop
      (br_if $loop
        (f64.gt
          (f64.add
            (local.tee $x
              (f64.mul
                (local.tee $result (local.get $x))
                (f64.const 0.5)
              )
            )
            (f64.const 1)
          )
          (f64.const 1)
        )
      )
    )
    (local.get $result)
  )
)
