(assert_invalid
  (module
    (type $t (func (result i32)))
    (func $g (param $r (ref $t)) (drop (ref.as_non_null (local.get $r))))
    (func (call $g (ref.null $t)))
  )
  "type mismatch"
)
