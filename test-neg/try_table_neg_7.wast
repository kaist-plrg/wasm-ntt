(assert_invalid
  (module
    (tag (param i64))
    (func (result i32 exnref) (try_table (result i32) (catch_ref 0 0) (i32.const 42)))
  )
  "type mismatch"
)
