(module
  (type $t (func (param i32) (result i32)))
  (elem func $f)
  (func $f (param i32) (result i32) (i32.mul (local.get 0) (local.get 0)))

  (func $a (param $n i32) (param $r (ref null $t)) (result i32)
    (block $l (result i32)
      (return (call_ref $t (br_on_null $l (local.get $n) (local.get $r))))
    )
  )

  (func (export "args-null") (param $n i32) (result i32)
    (call $a (local.get $n) (ref.null $t))
  )
  (func (export "args-f") (param $n i32) (result i32)
    (call $a (local.get $n) (ref.func $f))
  )
)
