(module
  (type $t (func))
  (table (import "Mtable_ex" "t-funcnull") 1 (ref null func))
  (table (import "Mtable_ex" "t-refnull") 1 (ref null $t))
  (table (import "Mtable_ex" "t-extern") 1 externref)
)
