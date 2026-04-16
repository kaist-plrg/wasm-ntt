(module
  (type $t (func))
  (func (export "unreachable") (result i32)
    (unreachable)
    (call_ref $t)
  )
)
