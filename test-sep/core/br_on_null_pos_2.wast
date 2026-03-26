(module
  (type $t (func))
  (func (param $r (ref null $t)) (drop (br_on_null 0 (local.get $r))))
  (func (param $r (ref null func)) (drop (br_on_null 0 (local.get $r))))
  (func (param $r (ref null extern)) (drop (br_on_null 0 (local.get $r))))
)
