(assert_invalid (module (tag (param i32)) (func (throw 0)))
                "type mismatch: instruction requires [i32] but stack has []")
