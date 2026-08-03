(module $Mtable_ex
  (type $t (func))
  (table (export "t-funcnull") 1 (ref null func))
  (table (export "t-refnull") 1 (ref null $t))
  (table (export "t-extern") 1 externref)
)

(register "Mtable_ex" $Mtable_ex)

(module
  (type $t (func))
  (table (import "Mtable_ex" "t-funcnull") 1 (ref null func))
  (table (import "Mtable_ex" "t-refnull") 1 (ref null $t))
  (table (import "Mtable_ex" "t-extern") 1 externref)
)
