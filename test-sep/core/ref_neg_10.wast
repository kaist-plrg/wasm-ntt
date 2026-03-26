(assert_invalid
  (module (func $loop-result-invalid (drop (loop (result (ref 1)) (unreachable)))))
  "unknown type"
)
