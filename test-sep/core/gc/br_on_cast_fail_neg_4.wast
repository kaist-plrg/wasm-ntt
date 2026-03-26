(assert_invalid
  (module
    (func (result anyref)
      (br_on_cast_fail 0 eqref anyref (unreachable))
    )
  )
  "type mismatch"
)
