(assert_invalid
  (module
    (type $ty (func (result i32 i32)))
    (import "env" "table" (table $table 0 funcref))
    (func (param i32) (result i32)
      local.get 0
      return_call_indirect $table (type $ty)
    )
  )
  "type mismatch"
)
