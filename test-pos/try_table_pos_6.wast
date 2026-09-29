(module
  (func (export "as-br-target") (result i32)
    (block
      (try_table
        (br 0)
        (unreachable)
      )
      (return (i32.const 111))
    )
    (i32.const 222)
  )

  (func (export "as-value-provider") (result i32)
    (block
      (try_table (result i32)
        (br 0 (i32.const 333))
      )
      (return)
    )
    (unreachable)
  )
)
