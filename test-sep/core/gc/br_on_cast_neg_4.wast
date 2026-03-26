(assert_invalid
  (module
    (func (result anyref)
      (br_on_cast 0 eqref anyref (unreachable))
    )
  )
  "type mismatch"
)
