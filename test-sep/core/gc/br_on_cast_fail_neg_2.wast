(assert_invalid
  (module
    (type $t (struct))
    (func (param (ref any)) (result (ref any))
      (block (result (ref null $t)) (br_on_cast_fail 1 (ref any) (ref null $t) (local.get 0))) (ref.as_non_null)
    )
  )
  "type mismatch"
)
