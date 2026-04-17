(module
  (func (export "i8x16.add_sat_s") (param v128 v128) (result v128) (i8x16.add_sat_s (local.get 0) (local.get 1)))
  (func (export "i8x16.add_sat_u") (param v128 v128) (result v128) (i8x16.add_sat_u (local.get 0) (local.get 1)))
  (func (export "i8x16.sub_sat_s") (param v128 v128) (result v128) (i8x16.sub_sat_s (local.get 0) (local.get 1)))
  (func (export "i8x16.sub_sat_u") (param v128 v128) (result v128) (i8x16.sub_sat_u (local.get 0) (local.get 1)))
)
