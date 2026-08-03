(module
  (type $arr (array funcref))

  (elem $e func $aa $bb $cc $dd)
  (func $aa (result i32) (i32.const 0xaa))
  (func $bb (result i32) (i32.const 0xbb))
  (func $cc (result i32) (i32.const 0xcc))
  (func $dd (result i32) (i32.const 0xdd))

  (func (export "array-new-elem") (param i32 i32) (result (ref $arr))
    (array.new_elem $arr $e (local.get 0) (local.get 1))
  )
)
