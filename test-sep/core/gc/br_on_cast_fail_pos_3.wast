(module
  (type $t (struct))

  (func (param (ref any)) (result (ref any))
    (block (result (ref $t)) (br_on_cast_fail 1 (ref any) (ref $t) (local.get 0)))
  )
  (func (param (ref null any)) (result (ref null any))
    (block (result (ref $t)) (br_on_cast_fail 1 (ref null any) (ref $t) (local.get 0)))
  )
  (func (param (ref null any)) (result (ref null any))
    (block (result (ref null $t)) (br_on_cast_fail 1 (ref null any) (ref null $t) (local.get 0)))
  )
)
