(module (func (export "f") (param funcref)))
(assert_return (invoke "f" (ref.null extern)))
