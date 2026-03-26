(module
  (func (export "tau") (param i32) (result f64)
    (local f64 f64 f64 f64)
    f64.const 0x0p+0
    local.set 1
    block
      local.get 0
      i32.const 1
      i32.lt_s
      br_if 0
      f64.const 0x1p+0
      local.set 2
      f64.const 0x0p+0
      local.set 3
      loop
        local.get 1
        local.get 2
        f64.const 0x1p+3
        local.get 3
        f64.const 0x1p+3
        f64.mul
        local.tee 4
        f64.const 0x1p+0
        f64.add
        f64.div
        f64.const 0x1p+2
        local.get 4
        f64.const 0x1p+2
        f64.add
        f64.div
        f64.sub
        f64.const 0x1p+1
        local.get 4
        f64.const 0x1.4p+2
        f64.add
        f64.div
        f64.sub
        f64.const 0x1p+1
        local.get 4
        f64.const 0x1.8p+2
        f64.add
        f64.div
        f64.sub
        f64.mul
        f64.add
        local.set 1
        local.get 3
        f64.const 0x1p+0
        f64.add
        local.set 3
        local.get 2
        f64.const 0x1p-4
        f64.mul
        local.set 2
        local.get 0
        i32.const -1
        i32.add
        local.tee 0
        br_if 0
      end
    end
    local.get 1
  )
)
