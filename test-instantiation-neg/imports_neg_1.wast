(assert_invalid
  (module 
    (type (func (result i32)))
    (import "test" "func" (func (type 1)))
  )
  "unknown type"
)
