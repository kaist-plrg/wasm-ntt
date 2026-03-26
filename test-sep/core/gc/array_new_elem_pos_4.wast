(module
  (type $f (func (result i32)))
  (type $arr (array funcref))

  (elem $e func $aa $bb $cc $dd)
  (func $aa (result i32) (i32.const 0xaa))
  (func $bb (result i32) (i32.const 0xbb))
  (func $cc (result i32) (i32.const 0xcc))
  (func $dd (result i32) (i32.const 0xdd))

  (table $t 2 2 funcref)

  (func (export "array-new-elem-contents") (result i32 i32)
    (local (ref $arr))
    (local.set 0 (array.new_elem $arr $e (i32.const 1) (i32.const 2)))

    (table.set $t (i32.const 0) (array.get $arr (local.get 0) (i32.const 0)))
    (table.set $t (i32.const 1) (array.get $arr (local.get 0) (i32.const 1)))

    (call_indirect (type $f) (i32.const 0))
    (call_indirect (type $f) (i32.const 1))

  )
)
