(module
  (func $imported-throw (import "test" "throw"))
  (tag $e0)

  (func (export "imported-mismatch") (result i32)
    (block $h
      (try_table (result i32) (catch_all $h)
        (block $h0
          (try_table (result i32) (catch $e0 $h0)
            (i32.const 1)
            (call $imported-throw)
          )
          (return)
        )
        (i32.const 2)
      )
      (return)
    )
    (i32.const 3)
  )
)
