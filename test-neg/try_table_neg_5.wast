(assert_invalid
  (module (func (try_table (catch_all_ref 0))))
  "type mismatch"
)
