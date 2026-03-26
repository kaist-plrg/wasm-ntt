(module $Mtable_ex
  (type $t (func))
  (table (export "t-funcnull") 1 (ref null func))
  (table (export "t-refnull") 1 (ref null $t))
  (table (export "t-extern") 1 externref)
)
