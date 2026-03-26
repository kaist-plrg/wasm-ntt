(module $Tgit2
  ;; imported table limits should match, because external table size is 3 now
  (import "grown-imported-table" "table" (table 3 funcref))
  (func (export "size") (result i32) (table.size))
)
