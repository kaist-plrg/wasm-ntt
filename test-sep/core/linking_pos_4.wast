(module $Mg
  (global $glob (export "glob") i32 (i32.const 42))
  (func (export "get") (result i32) (global.get $glob))

  ;; export mutable globals
  (global $mut_glob (export "mut_glob") (mut i32) (i32.const 142))
  (func (export "get_mut") (result i32) (global.get $mut_glob))
  (func (export "set_mut") (param i32) (global.set $mut_glob (local.get 0)))
)
