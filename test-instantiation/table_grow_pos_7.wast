(module $Tgt
  (table (export "table") 1 funcref) ;; initial size is 1
  (func (export "grow") (result i32) (table.grow (ref.null func) (i32.const 1)))
)

(register "grown-table" $Tgt)

(assert_return (invoke $Tgt "grow") (i32.const 1))

(module $Tgit1
  ;; imported table limits should match, because external table size is 2 now
  (table (export "table") (import "grown-table" "table") 2 funcref)
  (func (export "grow") (result i32) (table.grow (ref.null func) (i32.const 1)))
)
