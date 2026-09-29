(module
  (type $t (func (result i32)))

  (func $nn (param $r (ref $t)) (result i32)
    (call_ref $t
      (block $l (result (ref $t))
        (br_on_non_null $l (local.get $r))
        (return (i32.const -1))
      )
    )
  )
  (func $n (param $r (ref null $t)) (result i32)
    (call_ref $t
      (block $l (result (ref $t))
        (br_on_non_null $l (local.get $r))
        (return (i32.const -1))
      )
    )
  )
  (func $n2 (param $r (ref null $t)) (result i32)
    (call_ref $t
      (ref.as_non_null
        (block $l (result (ref null $t))
          (br_on_non_null $l (local.get $r))
          (return (i32.const -2))
        )
      )
    )
  )

  (elem func $f)
  (func $f (result i32) (i32.const 7))

  (func (export "nonnullable-f") (result i32) (call $nn (ref.func $f)))
  (func (export "nullable-null") (result i32) (call $n (ref.null $t)))
  (func (export "nullable-f") (result i32) (call $n (ref.func $f)))
  (func (export "nullable2-null") (result i32) (call $n2 (ref.null $t)))
  (func (export "nullable2-f") (result i32) (call $n2 (ref.func $f)))

  (func (export "unreachable") (result i32)
    (block $l (result (ref $t))
      (br_on_non_null $l (unreachable))
      (return (i32.const -1))
    )
    (call_ref $t)
  )
)
