(module
  (func (export "ef0") (result i32) (i32.const 0))
  (func (export "ef1") (result i32) (i32.const 1))
  (func (export "ef2") (result i32) (i32.const 2))
  (func (export "ef3") (result i32) (i32.const 3))
  (func (export "ef4") (result i32) (i32.const 4))
)

(register "a")

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t0) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t0) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (elem (table $t1) (i32.const 3) func 1 3 1 4)
  (elem (table $t1) (i32.const 11) func 6 3 2 5 7)
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (nop))
  (func (export "check_t0") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
  (func (export "check_t1") (param i32) (result i32)
    (call_indirect $t1 (type 0) (local.get 0)))
)

(invoke "test")

(assert_return (invoke "check_t0" (i32.const 2)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 4)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 12)) (i32.const 7))

(assert_return (invoke "check_t0" (i32.const 13)) (i32.const 5))

(assert_return (invoke "check_t0" (i32.const 14)) (i32.const 2))

(assert_return (invoke "check_t0" (i32.const 15)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 16)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 4)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 6)) (i32.const 4))

(assert_return (invoke "check_t1" (i32.const 11)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 12)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 13)) (i32.const 2))

(assert_return (invoke "check_t1" (i32.const 14)) (i32.const 5))

(assert_return (invoke "check_t1" (i32.const 15)) (i32.const 7))

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t0) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t0) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (elem (table $t1) (i32.const 3) func 1 3 1 4)
  (elem (table $t1) (i32.const 11) func 6 3 2 5 7)
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (table.copy $t0 $t0 (i32.const 13) (i32.const 2) (i32.const 3)))
  (func (export "check_t0") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
  (func (export "check_t1") (param i32) (result i32)
    (call_indirect $t1 (type 0) (local.get 0)))
)

(invoke "test")

(assert_return (invoke "check_t0" (i32.const 2)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 4)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 12)) (i32.const 7))

(assert_return (invoke "check_t0" (i32.const 13)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 14)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 15)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 16)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 4)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 6)) (i32.const 4))

(assert_return (invoke "check_t1" (i32.const 11)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 12)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 13)) (i32.const 2))

(assert_return (invoke "check_t1" (i32.const 14)) (i32.const 5))

(assert_return (invoke "check_t1" (i32.const 15)) (i32.const 7))

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t0) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t0) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (elem (table $t1) (i32.const 3) func 1 3 1 4)
  (elem (table $t1) (i32.const 11) func 6 3 2 5 7)
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (table.copy $t0 $t0 (i32.const 25) (i32.const 15) (i32.const 2)))
  (func (export "check_t0") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
  (func (export "check_t1") (param i32) (result i32)
    (call_indirect $t1 (type 0) (local.get 0)))
)

(invoke "test")

(assert_return (invoke "check_t0" (i32.const 2)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 4)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 12)) (i32.const 7))

(assert_return (invoke "check_t0" (i32.const 13)) (i32.const 5))

(assert_return (invoke "check_t0" (i32.const 14)) (i32.const 2))

(assert_return (invoke "check_t0" (i32.const 15)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 16)) (i32.const 6))

(assert_return (invoke "check_t0" (i32.const 25)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 26)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 4)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 6)) (i32.const 4))

(assert_return (invoke "check_t1" (i32.const 11)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 12)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 13)) (i32.const 2))

(assert_return (invoke "check_t1" (i32.const 14)) (i32.const 5))

(assert_return (invoke "check_t1" (i32.const 15)) (i32.const 7))

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t0) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t0) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (elem (table $t1) (i32.const 3) func 1 3 1 4)
  (elem (table $t1) (i32.const 11) func 6 3 2 5 7)
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (table.copy $t0 $t0 (i32.const 13) (i32.const 25) (i32.const 3)))
  (func (export "check_t0") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
  (func (export "check_t1") (param i32) (result i32)
    (call_indirect $t1 (type 0) (local.get 0)))
)

(invoke "test")

(assert_return (invoke "check_t0" (i32.const 2)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 4)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 12)) (i32.const 7))

(assert_return (invoke "check_t0" (i32.const 16)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 4)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 6)) (i32.const 4))

(assert_return (invoke "check_t1" (i32.const 11)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 12)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 13)) (i32.const 2))

(assert_return (invoke "check_t1" (i32.const 14)) (i32.const 5))

(assert_return (invoke "check_t1" (i32.const 15)) (i32.const 7))

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t0) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t0) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (elem (table $t1) (i32.const 3) func 1 3 1 4)
  (elem (table $t1) (i32.const 11) func 6 3 2 5 7)
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (table.copy $t0 $t0 (i32.const 20) (i32.const 22) (i32.const 4)))
  (func (export "check_t0") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
  (func (export "check_t1") (param i32) (result i32)
    (call_indirect $t1 (type 0) (local.get 0)))
)

(invoke "test")

(assert_return (invoke "check_t0" (i32.const 2)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 4)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 12)) (i32.const 7))

(assert_return (invoke "check_t0" (i32.const 13)) (i32.const 5))

(assert_return (invoke "check_t0" (i32.const 14)) (i32.const 2))

(assert_return (invoke "check_t0" (i32.const 15)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 16)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 4)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 6)) (i32.const 4))

(assert_return (invoke "check_t1" (i32.const 11)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 12)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 13)) (i32.const 2))

(assert_return (invoke "check_t1" (i32.const 14)) (i32.const 5))

(assert_return (invoke "check_t1" (i32.const 15)) (i32.const 7))

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t0) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t0) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (elem (table $t1) (i32.const 3) func 1 3 1 4)
  (elem (table $t1) (i32.const 11) func 6 3 2 5 7)
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (table.copy $t0 $t0 (i32.const 25) (i32.const 1) (i32.const 3)))
  (func (export "check_t0") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
  (func (export "check_t1") (param i32) (result i32)
    (call_indirect $t1 (type 0) (local.get 0)))
)

(invoke "test")

(assert_return (invoke "check_t0" (i32.const 2)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 4)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 12)) (i32.const 7))

(assert_return (invoke "check_t0" (i32.const 13)) (i32.const 5))

(assert_return (invoke "check_t0" (i32.const 14)) (i32.const 2))

(assert_return (invoke "check_t0" (i32.const 15)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 16)) (i32.const 6))

(assert_return (invoke "check_t0" (i32.const 26)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 27)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 4)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 6)) (i32.const 4))

(assert_return (invoke "check_t1" (i32.const 11)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 12)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 13)) (i32.const 2))

(assert_return (invoke "check_t1" (i32.const 14)) (i32.const 5))

(assert_return (invoke "check_t1" (i32.const 15)) (i32.const 7))

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t0) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t0) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (elem (table $t1) (i32.const 3) func 1 3 1 4)
  (elem (table $t1) (i32.const 11) func 6 3 2 5 7)
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (table.copy $t0 $t0 (i32.const 10) (i32.const 12) (i32.const 7)))
  (func (export "check_t0") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
  (func (export "check_t1") (param i32) (result i32)
    (call_indirect $t1 (type 0) (local.get 0)))
)

(invoke "test")

(assert_return (invoke "check_t0" (i32.const 2)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 4)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 10)) (i32.const 7))

(assert_return (invoke "check_t0" (i32.const 11)) (i32.const 5))

(assert_return (invoke "check_t0" (i32.const 12)) (i32.const 2))

(assert_return (invoke "check_t0" (i32.const 13)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 14)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 4)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 6)) (i32.const 4))

(assert_return (invoke "check_t1" (i32.const 11)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 12)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 13)) (i32.const 2))

(assert_return (invoke "check_t1" (i32.const 14)) (i32.const 5))

(assert_return (invoke "check_t1" (i32.const 15)) (i32.const 7))

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t0) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t0) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (elem (table $t1) (i32.const 3) func 1 3 1 4)
  (elem (table $t1) (i32.const 11) func 6 3 2 5 7)
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (table.copy $t0 $t0 (i32.const 12) (i32.const 10) (i32.const 7)))
  (func (export "check_t0") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
  (func (export "check_t1") (param i32) (result i32)
    (call_indirect $t1 (type 0) (local.get 0)))
)

(invoke "test")

(assert_return (invoke "check_t0" (i32.const 2)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 4)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 14)) (i32.const 7))

(assert_return (invoke "check_t0" (i32.const 15)) (i32.const 5))

(assert_return (invoke "check_t0" (i32.const 16)) (i32.const 2))

(assert_return (invoke "check_t0" (i32.const 17)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 18)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 4)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 6)) (i32.const 4))

(assert_return (invoke "check_t1" (i32.const 11)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 12)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 13)) (i32.const 2))

(assert_return (invoke "check_t1" (i32.const 14)) (i32.const 5))

(assert_return (invoke "check_t1" (i32.const 15)) (i32.const 7))

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t0) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t0) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (elem (table $t1) (i32.const 3) func 1 3 1 4)
  (elem (table $t1) (i32.const 11) func 6 3 2 5 7)
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (table.copy $t1 $t0 (i32.const 10) (i32.const 0) (i32.const 20)))
  (func (export "check_t0") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
  (func (export "check_t1") (param i32) (result i32)
    (call_indirect $t1 (type 0) (local.get 0)))
)

(invoke "test")

(assert_return (invoke "check_t0" (i32.const 2)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 4)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 12)) (i32.const 7))

(assert_return (invoke "check_t0" (i32.const 13)) (i32.const 5))

(assert_return (invoke "check_t0" (i32.const 14)) (i32.const 2))

(assert_return (invoke "check_t0" (i32.const 15)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 16)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 4)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 6)) (i32.const 4))

(assert_return (invoke "check_t1" (i32.const 12)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 13)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 14)) (i32.const 4))

(assert_return (invoke "check_t1" (i32.const 15)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 22)) (i32.const 7))

(assert_return (invoke "check_t1" (i32.const 23)) (i32.const 5))

(assert_return (invoke "check_t1" (i32.const 24)) (i32.const 2))

(assert_return (invoke "check_t1" (i32.const 25)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 26)) (i32.const 6))

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t1) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t1) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (elem (table $t0) (i32.const 3) func 1 3 1 4)
  (elem (table $t0) (i32.const 11) func 6 3 2 5 7)
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (nop))
  (func (export "check_t0") (param i32) (result i32)
    (call_indirect $t1 (type 0) (local.get 0)))
  (func (export "check_t1") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
)

(invoke "test")

(assert_return (invoke "check_t0" (i32.const 2)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 4)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 12)) (i32.const 7))

(assert_return (invoke "check_t0" (i32.const 13)) (i32.const 5))

(assert_return (invoke "check_t0" (i32.const 14)) (i32.const 2))

(assert_return (invoke "check_t0" (i32.const 15)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 16)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 4)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 6)) (i32.const 4))

(assert_return (invoke "check_t1" (i32.const 11)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 12)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 13)) (i32.const 2))

(assert_return (invoke "check_t1" (i32.const 14)) (i32.const 5))

(assert_return (invoke "check_t1" (i32.const 15)) (i32.const 7))

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t1) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t1) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (elem (table $t0) (i32.const 3) func 1 3 1 4)
  (elem (table $t0) (i32.const 11) func 6 3 2 5 7)
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (table.copy $t1 $t1 (i32.const 13) (i32.const 2) (i32.const 3)))
  (func (export "check_t0") (param i32) (result i32)
    (call_indirect $t1 (type 0) (local.get 0)))
  (func (export "check_t1") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
)

(invoke "test")

(assert_return (invoke "check_t0" (i32.const 2)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 4)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 12)) (i32.const 7))

(assert_return (invoke "check_t0" (i32.const 13)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 14)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 15)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 16)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 4)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 6)) (i32.const 4))

(assert_return (invoke "check_t1" (i32.const 11)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 12)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 13)) (i32.const 2))

(assert_return (invoke "check_t1" (i32.const 14)) (i32.const 5))

(assert_return (invoke "check_t1" (i32.const 15)) (i32.const 7))

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t1) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t1) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (elem (table $t0) (i32.const 3) func 1 3 1 4)
  (elem (table $t0) (i32.const 11) func 6 3 2 5 7)
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (table.copy $t1 $t1 (i32.const 25) (i32.const 15) (i32.const 2)))
  (func (export "check_t0") (param i32) (result i32)
    (call_indirect $t1 (type 0) (local.get 0)))
  (func (export "check_t1") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
)

(invoke "test")

(assert_return (invoke "check_t0" (i32.const 2)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 4)) (i32.const 4))

(assert_return (invoke "check_t0" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t0" (i32.const 12)) (i32.const 7))

(assert_return (invoke "check_t0" (i32.const 13)) (i32.const 5))

(assert_return (invoke "check_t0" (i32.const 14)) (i32.const 2))

(assert_return (invoke "check_t0" (i32.const 15)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 16)) (i32.const 6))

(assert_return (invoke "check_t0" (i32.const 25)) (i32.const 3))

(assert_return (invoke "check_t0" (i32.const 26)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 3)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 4)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 5)) (i32.const 1))

(assert_return (invoke "check_t1" (i32.const 6)) (i32.const 4))

(assert_return (invoke "check_t1" (i32.const 11)) (i32.const 6))

(assert_return (invoke "check_t1" (i32.const 12)) (i32.const 3))

(assert_return (invoke "check_t1" (i32.const 13)) (i32.const 2))

(assert_return (invoke "check_t1" (i32.const 14)) (i32.const 5))

(assert_return (invoke "check_t1" (i32.const 15)) (i32.const 7))

(module
  (type (func (result i32)))  ;; type #0
  (import "a" "ef0" (func (result i32)))    ;; index 0
  (import "a" "ef1" (func (result i32)))
  (import "a" "ef2" (func (result i32)))
  (import "a" "ef3" (func (result i32)))
  (import "a" "ef4" (func (result i32)))    ;; index 4
  (table $t0 30 30 funcref)
  (table $t1 30 30 funcref)
  (elem (table $t1) (i32.const 2) func 3 1 4 1)
  (elem funcref
    (ref.func 2) (ref.func 7) (ref.func 1) (ref.func 8))
  (elem (table $t1) (i32.const 12) func 7 5 2 3 6)
  (elem funcref
    (ref.func 5) (ref.func 9) (ref.func 2) (ref.func 7) (ref.func 6))
  (elem (table $t0) (i32.const 3) func 1 3 1 4)
  (elem (table $t0) (i32.const 11) func 6 3 2 5 7)
  (func (result i32) (i32.const 5))  ;; index 5
  (func (result i32) (i32.const 6))
  (func (result i32) (i32.const 7))
  (func (result i32) (i32.const 8))
  (func (result i32) (i32.const 9))  ;; index 9
  (func (export "test")
    (table.copy $t1 $t1 (i32.const 13) (i32.const 25) (i32.const 3)))
  (func (export "check_t0") (param i32) (result i32)
    (call_indirect $t1 (type 0) (local.get 0)))
  (func (export "check_t1") (param i32) (result i32)
    (call_indirect $t0 (type 0) (local.get 0)))
)
