(assert_invalid
  (module
    (func (export "eq") (param $r (ref extern)) (result i32)
      (ref.eq (local.get $r) (local.get $r))
    )
  )
  "type mismatch"
)
