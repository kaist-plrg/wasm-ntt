(assert_invalid
  (module
    (func (result anyref)
      (br_on_cast 0 structref arrayref (unreachable))
    )
  )
  "type mismatch"
)
