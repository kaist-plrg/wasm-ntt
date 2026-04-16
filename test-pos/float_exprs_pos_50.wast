(module
  (func (export "f32.incorrect_correction") (result f32)
    (f32.sub (f32.sub (f32.add (f32.const 1.333) (f32.const 1.225)) (f32.const 1.333)) (f32.const 1.225))
  )
  (func (export "f64.incorrect_correction") (result f64)
    (f64.sub (f64.sub (f64.add (f64.const 1.333) (f64.const 1.225)) (f64.const 1.333)) (f64.const 1.225))
  )
)
