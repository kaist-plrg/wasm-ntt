(module
  (func (export "i16x8.add_sat_s") (param v128 v128) (result v128) (i16x8.add_sat_s (local.get 0) (local.get 1)))
  (func (export "i16x8.add_sat_u") (param v128 v128) (result v128) (i16x8.add_sat_u (local.get 0) (local.get 1)))
  (func (export "i16x8.sub_sat_s") (param v128 v128) (result v128) (i16x8.sub_sat_s (local.get 0) (local.get 1)))
  (func (export "i16x8.sub_sat_u") (param v128 v128) (result v128) (i16x8.sub_sat_u (local.get 0) (local.get 1)))
)
