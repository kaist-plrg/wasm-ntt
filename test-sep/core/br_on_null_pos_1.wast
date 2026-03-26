(module
  (type $t (func (result i32)))

  (func $nn (param $r (ref $t)) (result i32)
    (block $l
      (return (call_ref $t (br_on_null $l (local.get $r))))
    )
    (i32.const -1)
  )
  (func $n (param $r (ref null $t)) (result i32)
    (block $l
      (return (call_ref $t (br_on_null $l (local.get $r))))
    )
    (i32.const -1)
  )

  (elem func $f)
  (func $f (result i32) (i32.const 7))

  (func (export "nullable-null") (result i32) (call $n (ref.null $t)))
  (func (export "nonnullable-f") (result i32) (call $nn (ref.func $f)))
  (func (export "nullable-f") (result i32) (call $n (ref.func $f)))

  (func (export "unreachable") (result i32)
    (block $l
      (return (call_ref $t (br_on_null $l (unreachable))))
    )
    (i32.const -1)
  )
)
