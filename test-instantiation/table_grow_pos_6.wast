(module $Tgt
  (table (export "table") 1 funcref) ;; initial size is 1
  (func (export "grow") (result i32) (table.grow (ref.null func) (i32.const 1)))
)
