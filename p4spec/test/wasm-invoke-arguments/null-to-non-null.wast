(module (func (export "f") (param (ref func))))
(assert_return (invoke "f" (ref.null func)))
