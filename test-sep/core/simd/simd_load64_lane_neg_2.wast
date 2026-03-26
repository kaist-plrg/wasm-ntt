(assert_invalid  (module (memory 1)
          (func (param $x v128) (result v128)
            (v128.load64_lane 2 (i32.const 0) (local.get $x))))
  "invalid lane index")
