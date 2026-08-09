(assert_invalid
  (module (func $if-invalid (drop (if (result (ref 1)) (then) (else)))))
  "unknown type"
)
