(module
  (type $t (func))
  (func (export "anyref") (result anyref) (ref.null any))
  (func (export "funcref") (result funcref) (ref.null func))
  (func (export "exnref") (result exnref) (ref.null exn))
  (func (export "externref") (result externref) (ref.null extern))
  (func (export "ref") (result (ref null $t)) (ref.null $t))

  (global anyref (ref.null any))
  (global funcref (ref.null func))
  (global exnref (ref.null exn))
  (global externref (ref.null extern))
  (global (ref null $t) (ref.null $t))
)
