(module
  (type $t (func))
  (func (param $r (ref null $t)) (drop (block (result (ref $t)) (br_on_non_null 0 (local.get $r)) (unreachable))))
  (func (param $r (ref null func)) (drop (block (result (ref func)) (br_on_non_null 0 (local.get $r)) (unreachable))))
  (func (param $r (ref null extern)) (drop (block (result (ref extern)) (br_on_non_null 0 (local.get $r)) (unreachable))))
)
