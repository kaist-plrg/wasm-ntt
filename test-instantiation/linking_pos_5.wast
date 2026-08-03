(module $Mg
  (global $glob (export "glob") i32 (i32.const 42))
  (func (export "get") (result i32) (global.get $glob))

  ;; export mutable globals
  (global $mut_glob (export "mut_glob") (mut i32) (i32.const 142))
  (func (export "get_mut") (result i32) (global.get $mut_glob))
  (func (export "set_mut") (param i32) (global.set $mut_glob (local.get 0)))
)

(register "Mg" $Mg)

(module $Ng
  (global $x (import "Mg" "glob") i32)
  (global $mut_glob (import "Mg" "mut_glob") (mut i32))
  (func $f (import "Mg" "get") (result i32))
  (func $get_mut (import "Mg" "get_mut") (result i32))
  (func $set_mut (import "Mg" "set_mut") (param i32))

  (export "Mg.glob" (global $x))
  (export "Mg.get" (func $f))
  (global $glob (export "glob") i32 (i32.const 43))
  (func (export "get") (result i32) (global.get $glob))

  (export "Mg.mut_glob" (global $mut_glob))
  (export "Mg.get_mut" (func $get_mut))
  (export "Mg.set_mut" (func $set_mut))
)
