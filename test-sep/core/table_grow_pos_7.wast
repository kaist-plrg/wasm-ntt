(module $Tgit1
  ;; imported table limits should match, because external table size is 2 now
  (table (export "table") (import "grown-table" "table") 2 funcref)
  (func (export "grow") (result i32) (table.grow (ref.null func) (i32.const 1)))
)
