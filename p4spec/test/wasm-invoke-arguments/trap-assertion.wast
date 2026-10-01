(module (func (export "f") (param i32) unreachable))
(assert_trap (invoke "f") "unreachable")
