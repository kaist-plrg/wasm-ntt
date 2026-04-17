(module
  (global (import "spectest" "global_i32") i32)
  (table 10 funcref)
  (func (result i32) (i32.const 42))
  (func (export "call_in_table") (param i32) (result i32)
    (call_indirect (type 0) (local.get 0)))
  (elem (table 0)
        (offset
          (i32.mul
            (i32.const 2)
            (i32.add
              (i32.sub (global.get 0) (i32.const 665))
              (i32.const 2))))
        funcref
        (ref.func 0))
)
