(assert_invalid
  (module
    (type $t (struct))
    (func (param (ref any)) (result (ref null $t))
      (block (result (ref any)) (br_on_cast 1 (ref any) (ref null $t) (local.get 0))) (unreachable)
    )
  )
  "type mismatch"
)
