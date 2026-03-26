(module
  (func (export "f32.sqrt") (param f32) (result f32)
    (f32.sqrt (local.get 0)))

  (func (export "f32.xkcd_sqrt_2") (param f32) (param f32) (param f32) (param f32) (result f32)
    (f32.add (f32.div (local.get 0) (local.get 1)) (f32.div (local.get 2) (f32.sub (local.get 3) (local.get 2)))))

  (func (export "f32.xkcd_sqrt_3") (param f32) (param f32) (param f32) (result f32)
    (f32.div (f32.mul (local.get 0) (local.get 1)) (local.get 2)))

  (func (export "f32.xkcd_sqrt_5") (param f32) (param f32) (param f32) (result f32)
    (f32.add (f32.div (local.get 0) (local.get 1)) (f32.div (local.get 2) (local.get 0))))

  (func (export "f32.xkcd_better_sqrt_5") (param f32) (param f32) (param f32) (param f32) (result f32)
    (f32.div (f32.add (local.get 0) (f32.mul (local.get 1) (local.get 2))) (f32.sub (local.get 3) (f32.mul (local.get 1) (local.get 2)))))

  (func (export "f64.sqrt") (param f64) (result f64)
    (f64.sqrt (local.get 0)))

  (func (export "f64.xkcd_sqrt_2") (param f64) (param f64) (param f64) (param f64) (result f64)
    (f64.add (f64.div (local.get 0) (local.get 1)) (f64.div (local.get 2) (f64.sub (local.get 3) (local.get 2)))))

  (func (export "f64.xkcd_sqrt_3") (param f64) (param f64) (param f64) (result f64)
    (f64.div (f64.mul (local.get 0) (local.get 1)) (local.get 2)))

  (func (export "f64.xkcd_sqrt_5") (param f64) (param f64) (param f64) (result f64)
    (f64.add (f64.div (local.get 0) (local.get 1)) (f64.div (local.get 2) (local.get 0))))

  (func (export "f64.xkcd_better_sqrt_5") (param f64) (param f64) (param f64) (param f64) (result f64)
    (f64.div (f64.add (local.get 0) (f64.mul (local.get 1) (local.get 2))) (f64.sub (local.get 3) (f64.mul (local.get 1) (local.get 2)))))
)
