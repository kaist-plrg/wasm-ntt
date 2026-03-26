(module
  (memory 1)
  (data (i32.const 0) "\00\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F")
  (data (i32.const 65520) "\10\11\12\13\14\15\16\17\18\19\1A\1B\1C\1D\1E\1F")

  (func (export "v128.load8_splat") (param $address i32) (result v128) (v128.load8_splat (local.get $address)))
  (func (export "v128.load16_splat") (param $address i32) (result v128) (v128.load16_splat (local.get $address)))
  (func (export "v128.load32_splat") (param $address i32) (result v128) (v128.load32_splat (local.get $address)))
  (func (export "v128.load64_splat") (param $address i32) (result v128) (v128.load64_splat (local.get $address)))

  ;; Load data with different offset/align arguments
  (func (export "v8x16.offset0") (param $address i32) (result v128) (v128.load8_splat offset=0 (local.get $address)))
  (func (export "v8x16.align1") (param $address i32) (result v128) (v128.load8_splat align=1 (local.get $address)))
  (func (export "v8x16.offset1_align1") (param $address i32) (result v128) (v128.load8_splat offset=1 align=1 (local.get $address)))
  (func (export "v8x16.offset2_align1") (param $address i32) (result v128) (v128.load8_splat offset=2 align=1 (local.get $address)))
  (func (export "v8x16.offset15_align1") (param $address i32) (result v128) (v128.load8_splat offset=15 align=1 (local.get $address)))

  (func (export "v16x8.offset0") (param $address i32) (result v128) (v128.load16_splat offset=0 (local.get $address)))
  (func (export "v16x8.align1") (param $address i32) (result v128) (v128.load16_splat align=1 (local.get $address)))
  (func (export "v16x8.offset1_align1") (param $address i32) (result v128) (v128.load16_splat offset=1 align=1 (local.get $address)))
  (func (export "v16x8.offset2_align1") (param $address i32) (result v128) (v128.load16_splat offset=2 align=1 (local.get $address)))
  (func (export "v16x8.offset15_align2") (param $address i32) (result v128) (v128.load16_splat offset=15 align=2 (local.get $address)))

  (func (export "v32x4.offset0") (param $address i32) (result v128) (v128.load32_splat offset=0 (local.get $address)))
  (func (export "v32x4.align1") (param $address i32) (result v128) (v128.load32_splat align=1 (local.get $address)))
  (func (export "v32x4.offset1_align1") (param $address i32) (result v128) (v128.load32_splat offset=1 align=1 (local.get $address)))
  (func (export "v32x4.offset2_align2") (param $address i32) (result v128) (v128.load32_splat offset=2 align=2 (local.get $address)))
  (func (export "v32x4.offset15_align4") (param $address i32) (result v128) (v128.load32_splat offset=15 align=4 (local.get $address)))

  (func (export "v64x2.offset0") (param $address i32) (result v128) (v128.load64_splat offset=0 (local.get $address)))
  (func (export "v64x2.align1") (param $address i32) (result v128) (v128.load64_splat align=1 (local.get $address)))
  (func (export "v64x2.offset1_align2") (param $address i32) (result v128) (v128.load64_splat offset=1 align=2 (local.get $address)))
  (func (export "v64x2.offset2_align4") (param $address i32) (result v128) (v128.load64_splat offset=2 align=4 (local.get $address)))
  (func (export "v64x2.offset15_align8") (param $address i32) (result v128) (v128.load64_splat offset=15 align=8 (local.get $address)))

  (func (export "v8x16.offset65536") (param $address i32) (result v128) (v128.load8_splat offset=65536 (local.get $address)))
  (func (export "v16x8.offset65535") (param $address i32) (result v128) (v128.load16_splat offset=65535 (local.get $address)))
  (func (export "v32x4.offset65533") (param $address i32) (result v128) (v128.load32_splat offset=65533 (local.get $address)))
  (func (export "v64x2.offset65529") (param $address i32) (result v128) (v128.load64_splat offset=65529 (local.get $address)))
)
