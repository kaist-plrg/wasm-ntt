(assert_invalid
  (module (func $select-result-invalid (drop (select (result (ref 1)) (unreachable)))))
  "unknown type"
)
