(assert_invalid
  (module (memory 1) (func (drop (v128.load (local.get 2)))))
  "unknown local 2"
)
