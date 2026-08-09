(assert_invalid
  (module (tag) (func (result exnref) (try_table (catch 0 0)) (unreachable)))
  "type mismatch"
)
