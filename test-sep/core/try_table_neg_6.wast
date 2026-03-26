(assert_invalid
  (module (func (result exnref) (try_table (catch_all 0)) (unreachable)))
  "type mismatch"
)
