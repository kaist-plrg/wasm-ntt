(module
  (func (export "tee-init") (param $p (ref extern)) (result (ref extern))
    (local $x (ref extern))
    (drop (local.tee $x (local.get $p)))
    (local.get $x)
  )
)
