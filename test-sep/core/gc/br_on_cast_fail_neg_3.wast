(assert_invalid
  (module
    (type $t (struct))
    (func (param (ref null any)) (result (ref any))
      (block (result (ref $t)) (br_on_cast_fail 1 (ref null any) (ref $t) (local.get 0)))
    )
  )
  "type mismatch"
)
