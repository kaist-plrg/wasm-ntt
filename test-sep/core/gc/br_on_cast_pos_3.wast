(module
  (type $t (struct))

  (func (param (ref any)) (result (ref $t))
    (block (result (ref any)) (br_on_cast 1 (ref any) (ref $t) (local.get 0))) (unreachable)
  )
  (func (param (ref null any)) (result (ref $t))
    (block (result (ref null any)) (br_on_cast 1 (ref null any) (ref $t) (local.get 0))) (unreachable)
  )
  (func (param (ref null any)) (result (ref null $t))
    (block (result (ref null any)) (br_on_cast 1 (ref null any) (ref null $t) (local.get 0))) (unreachable)
  )
)
