(module $m
  (table $t (export "table") 2 externref)
  (func (export "get") (param $i i32) (result externref)
        (table.get $t (local.get $i)))
  (func (export "set") (param $i i32) (param $x externref)
        (table.set $t (local.get $i) (local.get $x))))

(register "exporter" $m)

(assert_return (invoke $m "get" (i32.const 0)) (ref.null extern))

(assert_return (invoke $m "get" (i32.const 1)) (ref.null extern))

(assert_return (invoke $m "set" (i32.const 0) (ref.extern 42)))

(assert_return (invoke $m "set" (i32.const 1) (ref.extern 137)))

(assert_return (invoke $m "get" (i32.const 0)) (ref.extern 42))

(assert_return (invoke $m "get" (i32.const 1)) (ref.extern 137))

(module
  (import "exporter" "table" (table $t 2 externref))
  (elem (i32.const 0) externref (ref.null extern)))
