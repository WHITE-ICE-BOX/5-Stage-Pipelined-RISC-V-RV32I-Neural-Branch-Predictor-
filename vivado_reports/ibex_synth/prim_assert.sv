// Stub for prim_assert.sv — replaces all assertion macros with no-ops for synthesis
// lowRISC assertion macros are SVA-based and not needed for RTL synthesis

`ifndef PRIM_ASSERT_SV
`define PRIM_ASSERT_SV

`define ASSERT(NAME, PROP, CLK, RST)
`define ASSERT_INIT(NAME, PROP)
`define ASSERT_NEVER(NAME, PROP, CLK, RST)
`define ASSERT_KNOWN(NAME, SIGNAL, CLK, RST)
`define ASSERT_KNOWN_IF(NAME, SIGNAL, COND)
`define ASSERT_IF(NAME, PROP, CLK, RST, COND)

`endif
