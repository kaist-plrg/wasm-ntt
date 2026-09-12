(assert_invalid
  (module (memory 1) (func (local v128) (block (br_if 0 (v128.store)))))
  "type mismatch"
)
