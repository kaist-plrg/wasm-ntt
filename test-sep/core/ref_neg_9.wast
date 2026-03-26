(assert_invalid
  (module (func $block-result-invalid (drop (block (result (ref 1)) (unreachable)))))
  "unknown type"
)
