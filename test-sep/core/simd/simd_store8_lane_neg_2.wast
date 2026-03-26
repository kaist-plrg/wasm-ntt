(assert_invalid  (module (memory 1)
          (func (param $x v128) (result v128)
            (v128.store8_lane 16 (i32.const 0) (local.get $x))))
  "invalid lane index")
