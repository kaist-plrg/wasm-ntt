(module
  (type $t (func))
  (func (param $r (ref $t)) (drop (ref.as_non_null (local.get $r))))
  (func (param $r (ref func)) (drop (ref.as_non_null (local.get $r))))
  (func (param $r (ref extern)) (drop (ref.as_non_null (local.get $r))))
)
