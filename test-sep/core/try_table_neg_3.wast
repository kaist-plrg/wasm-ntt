(assert_invalid
  (module (tag) (func (try_table (catch_ref 0 0))))
  "type mismatch"
)
