(module definition $M
  (global (export "glob") (mut i32) (i32.const 0))
  (table (export "tab") 10 funcref (ref.null func))
  (memory (export "mem") 1)
  (tag (export "tag"))
)

(module instance $I1 $M)

(module instance $I2 $M)

(register "I1" $I1)

(register "I2" $I2)

(module
  (import "I1" "glob" (global $glob1 (mut i32)))
  (import "I2" "glob" (global $glob2 (mut i32)))
  (import "I1" "tab" (table $tab1 10 funcref))
  (import "I2" "tab" (table $tab2 10 funcref))
  (import "I1" "mem" (memory $mem1 1))
  (import "I2" "mem" (memory $mem2 1))
  (import "I1" "tag" (tag $tag1))
  (import "I2" "tag" (tag $tag2))

  (func $f)
  (elem declare func $f)

  (func (export "glob") (result i32)
    (global.set $glob1 (i32.const 1))
    (global.get $glob2)
  )
  (func (export "tab") (result funcref)
    (table.set $tab1 (i32.const 0) (ref.func $f))
    (table.get $tab2 (i32.const 0))
  )
  (func (export "mem") (result i32)
    (i32.store $mem1 (i32.const 0) (i32.const 1))
    (i32.load $mem2 (i32.const 0))
  )
  (func (export "tag") (result i32)
    (block $on_tag1
      (block $on_other
        (try_table (catch $tag1 $on_tag1) (catch_all $on_other)
          (throw $tag2)
        )
        (unreachable)
      )
      (return (i32.const 0))
    )
    (return (i32.const 1))
  )
)
