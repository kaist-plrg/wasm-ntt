(assert_invalid (module (tag (param i32)) (func (i64.const 5) (throw 0)))
                "type mismatch: instruction requires [i32] but stack has [i64]")
