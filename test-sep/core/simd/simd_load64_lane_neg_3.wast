(assert_invalid
  (module (memory 1)
          (func (param $x v128) (result v128)
          (v128.load64_lane align=16 0 (i32.const 0) (local.get $x))))
  "alignment must not be larger than natural")
