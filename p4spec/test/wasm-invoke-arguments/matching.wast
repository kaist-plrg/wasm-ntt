;; Arguments that the reference interpreter accepts, including reference
;; subtyping, an imported host function, and a re-export of it
(module $target
  (func $print_i32 (export "print_i32") (import "spectest" "print_i32") (param i32))
  (func (export "nums") (param i32 i64 f32 f64) (result i64) (local.get 1))
  (func (export "vec") (param v128) (result v128) (local.get 0))
  (func (export "func") (param funcref) (result i32) (ref.is_null (local.get 0)))
  (func (export "any") (param anyref) (result i32) (ref.is_null (local.get 0)))
  (func (export "extern") (param externref) (result externref) (local.get 0)))

(invoke "print_i32" (i32.const 1))
(assert_return
  (invoke "nums" (i32.const 0) (i64.const 1) (f32.const 2) (f64.const 3))
  (i64.const 1))
(assert_return (invoke "vec" (v128.const i32x4 1 2 3 4)) (v128.const i32x4 1 2 3 4))
(assert_return (invoke "func" (ref.null func)) (i32.const 1))
(assert_return (invoke "any" (ref.null none)) (i32.const 1))
(assert_return (invoke "any" (ref.host 1)) (i32.const 0))
(assert_return (invoke "extern" (ref.extern 1)) (ref.extern 1))
