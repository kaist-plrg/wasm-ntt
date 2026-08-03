(module
  (func (export "func"))
  (func (export "func-i32") (param i32))
  (func (export "func-f32") (param f32))
  (func (export "func->i32") (result i32) (i32.const 22))
  (func (export "func->f32") (result f32) (f32.const 11))
  (func (export "func-i32->i32") (param i32) (result i32) (local.get 0))
  (func (export "func-i64->i64") (param i64) (result i64) (local.get 0))
  (global (export "global-i32") i32 (i32.const 55))
  (global (export "global-f32") f32 (f32.const 44))
  (global (export "global-mut-i64") (mut i64) (i64.const 66))
  (table (export "table-10-inf") 10 funcref)
  (table (export "table-10-20") 10 20 funcref)
  (table (export "table64-10-inf") i64 10 funcref)
  (table (export "table64-10-20") i64 10 20 funcref)
  (memory (export "memory-2-inf") 2)
  (memory (export "memory-2-4") 2 4)
  (memory (export "memory64-2-inf") i64 2)
  (memory (export "memory64-2-4") i64 2 4)
  (tag (export "tag"))
  (tag $tag-i32 (param i32))
  (export "tag-i32" (tag $tag-i32))
  (tag (export "tag-f32") (param f32))
)

(register "test")

(module
  (type $func_i32 (func (param i32)))
  (type $func_i64 (func (param i64)))
  (type $func_f32 (func (param f32)))
  (type $func_f64 (func (param f64)))

  (import "spectest" "print_i32" (func (param i32)))
  (func (import "spectest" "print_i64") (param i64))
  (import "spectest" "print_i32" (func $print_i32 (param i32)))
  (import "spectest" "print_i64" (func $print_i64 (param i64)))
  (import "spectest" "print_f32" (func $print_f32 (param f32)))
  (import "spectest" "print_f64" (func $print_f64 (param f64)))
  (import "spectest" "print_i32_f32" (func $print_i32_f32 (param i32 f32)))
  (import "spectest" "print_f64_f64" (func $print_f64_f64 (param f64 f64)))
  (func $print_i32-2 (import "spectest" "print_i32") (param i32))
  (func $print_f64-2 (import "spectest" "print_f64") (param f64))
  (import "test" "func-i64->i64" (func $i64->i64 (param i64) (result i64)))

  (tag (import "test" "tag-i32") (param i32))
  (import "test" "tag-f32" (tag (param f32)))

  (func (export "p1") (import "spectest" "print_i32") (param i32))
  (func $p (export "p2") (import "spectest" "print_i32") (param i32))
  (func (export "p3") (export "p4") (import "spectest" "print_i32") (param i32))
  (func (export "p5") (import "spectest" "print_i32") (type 0))
  (func (export "p6") (import "spectest" "print_i32") (type 0) (param i32) (result))

  (import "spectest" "print_i32" (func (type $forward)))
  (func (import "spectest" "print_i32") (type $forward))
  (type $forward (func (param i32)))

  (table funcref (elem $print_i32 $print_f64))

  (func (export "print32") (param $i i32)
    (local $x f32)
    (local.set $x (f32.convert_i32_s (local.get $i)))
    (call 0 (local.get $i))
    (call $print_i32_f32
      (i32.add (local.get $i) (i32.const 1))
      (f32.const 42)
    )
    (call $print_i32 (local.get $i))
    (call $print_i32-2 (local.get $i))
    (call $print_f32 (local.get $x))
    (call_indirect (type $func_i32) (local.get $i) (i32.const 0))
  )

  (func (export "print64") (param $i i64)
    (local $x f64)
    (local.set $x (f64.convert_i64_s (call $i64->i64 (local.get $i))))
    (call 1 (local.get $i))
    (call $print_f64_f64
      (f64.add (local.get $x) (f64.const 1))
      (f64.const 53)
    )
    (call $print_i64 (local.get $i))
    (call $print_f64 (local.get $x))
    (call $print_f64-2 (local.get $x))
    (call_indirect (type $func_f64) (local.get $x) (i32.const 1))
  )
)

(assert_return (invoke "print32" (i32.const 13)))

(assert_return (invoke "print64" (i64.const 24)))

(module (import "test" "func" (func)))

(module (import "test" "func-i32" (func (param i32))))

(module (import "test" "func-f32" (func (param f32))))

(module (import "test" "func->i32" (func (result i32))))

(module (import "test" "func->f32" (func (result f32))))

(module (import "test" "func-i32->i32" (func (param i32) (result i32))))

(module (import "test" "func-i64->i64" (func (param i64) (result i64))))

(module (import "test" "global-i32" (global i32)))

(module (import "test" "global-f32" (global f32)))

(module (import "test" "global-mut-i64" (global (mut i64))))

(module
  (type (func (result i32)))
  (import "spectest" "table" (table $tab 10 20 funcref))
  (import "test" "table64-10-inf" (table $tab64 i64 10 funcref))
  (elem (table $tab) (i32.const 1) func $f $g)

  (func (export "call") (param i32) (result i32)
    (call_indirect $tab (type 0) (local.get 0))
  )
  (func $f (result i32) (i32.const 11))
  (func $g (result i32) (i32.const 22))
)

(assert_return (invoke "call" (i32.const 1)) (i32.const 11))

(assert_return (invoke "call" (i32.const 2)) (i32.const 22))

(module
  (type (func (result i32)))
  (table $tab (import "spectest" "table") 10 20 funcref)
  (table $tab64 (import "test" "table64-10-inf") i64 10 funcref)
  (elem (table $tab) (i32.const 1) func $f $g)

  (func (export "call") (param i32) (result i32)
    (call_indirect $tab (type 0) (local.get 0))
  )
  (func $f (result i32) (i32.const 11))
  (func $g (result i32) (i32.const 22))
)
