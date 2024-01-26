/*
 * Generated by Bluespec Compiler, version 2022.01 (build 066c7a8)
 * 
 * On Thu Nov 17 03:27:03 PST 2022
 * 
 */
#include "bluesim_primitives.h"
#include "mkTestDriver.h"


/* String declarations */
static std::string const __str_literal_7("%c", 2u);
static std::string const __str_literal_3("couldn't open in.pcm", 20u);
static std::string const __str_literal_6("couldn't open out.pcm for write", 31u);
static std::string const __str_literal_1("in.pcm", 6u);
static std::string const __str_literal_4("out.pcm", 7u);
static std::string const __str_literal_2("rb", 2u);
static std::string const __str_literal_5("wb", 2u);


/* Constructor */
MOD_mkTestDriver::MOD_mkTestDriver(tSimStateHdl simHdl, char const *name, Module *parent)
  : Module(simHdl, name, parent),
    __clk_handle_0(BAD_CLOCK_HANDLE),
    INST_m_doneread(simHdl, "m_doneread", this, 1u, (tUInt8)0u, (tUInt8)0u),
    INST_m_in(simHdl, "m_in", this, 32u),
    INST_m_inited(simHdl, "m_inited", this, 1u, (tUInt8)0u, (tUInt8)0u),
    INST_m_out(simHdl, "m_out", this, 32u),
    INST_m_outstanding(simHdl, "m_outstanding", this, 32u, 0u),
    INST_pipeline(simHdl, "pipeline", this),
    PORT_RST_N((tUInt8)1u),
    DEF_b__h978(2863311530u),
    DEF_x__h1135(2863311530u),
    DEF_TASK_fopen___d5(2863311530u),
    DEF_TASK_fopen___d3(2863311530u)
{
  symbol_count = 21u;
  symbols = new tSym[symbol_count];
  init_symbols_0();
}


/* Symbol init fns */

void MOD_mkTestDriver::init_symbols_0()
{
  init_symbol(&symbols[0u], "CAN_FIRE_RL_finish", SYM_DEF, &DEF_CAN_FIRE_RL_finish, 1u);
  init_symbol(&symbols[1u], "CAN_FIRE_RL_init", SYM_DEF, &DEF_CAN_FIRE_RL_init, 1u);
  init_symbol(&symbols[2u], "CAN_FIRE_RL_pad", SYM_DEF, &DEF_CAN_FIRE_RL_pad, 1u);
  init_symbol(&symbols[3u], "CAN_FIRE_RL_read", SYM_DEF, &DEF_CAN_FIRE_RL_read, 1u);
  init_symbol(&symbols[4u], "CAN_FIRE_RL_write", SYM_DEF, &DEF_CAN_FIRE_RL_write, 1u);
  init_symbol(&symbols[5u], "m_doneread", SYM_MODULE, &INST_m_doneread);
  init_symbol(&symbols[6u], "m_in", SYM_MODULE, &INST_m_in);
  init_symbol(&symbols[7u], "m_inited", SYM_MODULE, &INST_m_inited);
  init_symbol(&symbols[8u], "m_out", SYM_MODULE, &INST_m_out);
  init_symbol(&symbols[9u], "m_outstanding", SYM_MODULE, &INST_m_outstanding);
  init_symbol(&symbols[10u], "pipeline", SYM_MODULE, &INST_pipeline);
  init_symbol(&symbols[11u], "RL_finish", SYM_RULE);
  init_symbol(&symbols[12u], "RL_init", SYM_RULE);
  init_symbol(&symbols[13u], "RL_pad", SYM_RULE);
  init_symbol(&symbols[14u], "RL_read", SYM_RULE);
  init_symbol(&symbols[15u], "RL_write", SYM_RULE);
  init_symbol(&symbols[16u], "WILL_FIRE_RL_finish", SYM_DEF, &DEF_WILL_FIRE_RL_finish, 1u);
  init_symbol(&symbols[17u], "WILL_FIRE_RL_init", SYM_DEF, &DEF_WILL_FIRE_RL_init, 1u);
  init_symbol(&symbols[18u], "WILL_FIRE_RL_pad", SYM_DEF, &DEF_WILL_FIRE_RL_pad, 1u);
  init_symbol(&symbols[19u], "WILL_FIRE_RL_read", SYM_DEF, &DEF_WILL_FIRE_RL_read, 1u);
  init_symbol(&symbols[20u], "WILL_FIRE_RL_write", SYM_DEF, &DEF_WILL_FIRE_RL_write, 1u);
}


/* Rule actions */

void MOD_mkTestDriver::RL_init()
{
  tUInt8 DEF_TASK_fopen_EQ_0___d4;
  tUInt8 DEF_TASK_fopen_EQ_0___d6;
  INST_m_inited.METH_write((tUInt8)1u);
  if (!(PORT_RST_N == (tUInt8)0u))
    DEF_TASK_fopen___d3 = dollar_fopen("s,s", &__str_literal_1, &__str_literal_2);
  DEF_TASK_fopen_EQ_0___d4 = DEF_TASK_fopen___d3 == 0u;
  if (!(PORT_RST_N == (tUInt8)0u))
  {
    if (DEF_TASK_fopen_EQ_0___d4)
      dollar_display(sim_hdl, this, "s", &__str_literal_3);
    if (DEF_TASK_fopen_EQ_0___d4)
      dollar_finish(sim_hdl, "32", 1u);
  }
  INST_m_in.METH_write(DEF_TASK_fopen___d3);
  if (!(PORT_RST_N == (tUInt8)0u))
    DEF_TASK_fopen___d5 = dollar_fopen("s,s", &__str_literal_4, &__str_literal_5);
  DEF_TASK_fopen_EQ_0___d6 = DEF_TASK_fopen___d5 == 0u;
  if (!(PORT_RST_N == (tUInt8)0u))
  {
    if (DEF_TASK_fopen_EQ_0___d6)
      dollar_display(sim_hdl, this, "s", &__str_literal_6);
    if (DEF_TASK_fopen_EQ_0___d6)
      dollar_finish(sim_hdl, "32", 1u);
  }
  INST_m_out.METH_write(DEF_TASK_fopen___d5);
}

void MOD_mkTestDriver::RL_read()
{
  tUInt32 DEF_TASK_fgetc_9_BITS_7_TO_0_5_CONCAT_TASK_fgetc_7_ETC___d27;
  tUInt8 DEF_NOT_TASK_fgetc_7_EQ_4294967295_8_2_AND_NOT_TAS_ETC___d24;
  tUInt8 DEF_TASK_fgetc_7_EQ_4294967295_8_OR_TASK_fgetc_9_E_ETC___d21;
  tUInt8 DEF_TASK_fgetc_7_EQ_4294967295___d18;
  tUInt8 DEF_TASK_fgetc_9_EQ_4294967295___d20;
  tUInt8 DEF_a8__h1076;
  tUInt8 DEF_b8__h1077;
  tUInt32 DEF_m_in___d16;
  DEF_m_in___d16 = INST_m_in.METH_read();
  if (!(PORT_RST_N == (tUInt8)0u))
    DEF_x__h1135 = dollar_fgetc("32", DEF_m_in___d16);
  DEF_a8__h1076 = (tUInt8)((tUInt8)255u & DEF_x__h1135);
  DEF_TASK_fgetc_7_EQ_4294967295___d18 = DEF_x__h1135 == 4294967295u;
  if (!(PORT_RST_N == (tUInt8)0u))
    DEF_b__h978 = dollar_fgetc("32", DEF_m_in___d16);
  DEF_b8__h1077 = (tUInt8)((tUInt8)255u & DEF_b__h978);
  DEF_TASK_fgetc_9_EQ_4294967295___d20 = DEF_b__h978 == 4294967295u;
  DEF_TASK_fgetc_7_EQ_4294967295_8_OR_TASK_fgetc_9_E_ETC___d21 = DEF_TASK_fgetc_7_EQ_4294967295___d18 || DEF_TASK_fgetc_9_EQ_4294967295___d20;
  DEF_NOT_TASK_fgetc_7_EQ_4294967295_8_2_AND_NOT_TAS_ETC___d24 = !DEF_TASK_fgetc_7_EQ_4294967295___d18 && !DEF_TASK_fgetc_9_EQ_4294967295___d20;
  DEF_TASK_fgetc_9_BITS_7_TO_0_5_CONCAT_TASK_fgetc_7_ETC___d27 = 65535u & ((((tUInt32)(DEF_b8__h1077)) << 8u) | (tUInt32)(DEF_a8__h1076));
  if (DEF_TASK_fgetc_7_EQ_4294967295_8_OR_TASK_fgetc_9_E_ETC___d21)
    INST_m_doneread.METH_write((tUInt8)1u);
  if (!(PORT_RST_N == (tUInt8)0u))
    if (DEF_TASK_fgetc_7_EQ_4294967295_8_OR_TASK_fgetc_9_E_ETC___d21)
      dollar_fclose("32", DEF_m_in___d16);
  if (DEF_NOT_TASK_fgetc_7_EQ_4294967295_8_2_AND_NOT_TAS_ETC___d24)
    INST_pipeline.METH_putSampleInput(DEF_TASK_fgetc_9_BITS_7_TO_0_5_CONCAT_TASK_fgetc_7_ETC___d27);
  if (DEF_NOT_TASK_fgetc_7_EQ_4294967295_8_2_AND_NOT_TAS_ETC___d24)
    INST_m_outstanding.METH_addA(1u);
}

void MOD_mkTestDriver::RL_pad()
{
  INST_pipeline.METH_putSampleInput(0u);
}

void MOD_mkTestDriver::RL_write()
{
  tUInt8 DEF_a8__h1295;
  tUInt8 DEF_b8__h1296;
  tUInt32 DEF_pipeline_getSampleOutput___d33;
  tUInt32 DEF_AVMeth_pipeline_getSampleOutput;
  DEF_m_out___d32 = INST_m_out.METH_read();
  DEF_AVMeth_pipeline_getSampleOutput = INST_pipeline.METH_getSampleOutput();
  DEF_pipeline_getSampleOutput___d33 = DEF_AVMeth_pipeline_getSampleOutput;
  DEF_b8__h1296 = (tUInt8)(DEF_pipeline_getSampleOutput___d33 >> 8u);
  DEF_a8__h1295 = (tUInt8)((tUInt8)255u & DEF_pipeline_getSampleOutput___d33);
  INST_m_outstanding.METH_addB(4294967295u);
  if (!(PORT_RST_N == (tUInt8)0u))
  {
    dollar_fwrite(sim_hdl, this, "32,s,8", DEF_m_out___d32, &__str_literal_7, DEF_a8__h1295);
    dollar_fwrite(sim_hdl, this, "32,s,8", DEF_m_out___d32, &__str_literal_7, DEF_b8__h1296);
  }
}

void MOD_mkTestDriver::RL_finish()
{
  DEF_m_out___d32 = INST_m_out.METH_read();
  if (!(PORT_RST_N == (tUInt8)0u))
  {
    dollar_fclose("32", DEF_m_out___d32);
    dollar_finish(sim_hdl, "32", 1u);
  }
}


/* Methods */


/* Reset routines */

void MOD_mkTestDriver::reset_RST_N(tUInt8 ARG_rst_in)
{
  PORT_RST_N = ARG_rst_in;
  INST_pipeline.reset_RST_N(ARG_rst_in);
  INST_m_outstanding.reset_RST(ARG_rst_in);
  INST_m_inited.reset_RST(ARG_rst_in);
  INST_m_doneread.reset_RST(ARG_rst_in);
}


/* Static handles to reset routines */


/* Functions for the parent module to register its reset fns */


/* Functions to set the elaborated clock id */

void MOD_mkTestDriver::set_clk_0(char const *s)
{
  __clk_handle_0 = bk_get_or_define_clock(sim_hdl, s);
}


/* State dumping routine */
void MOD_mkTestDriver::dump_state(unsigned int indent)
{
  printf("%*s%s:\n", indent, "", inst_name);
  INST_m_doneread.dump_state(indent + 2u);
  INST_m_in.dump_state(indent + 2u);
  INST_m_inited.dump_state(indent + 2u);
  INST_m_out.dump_state(indent + 2u);
  INST_m_outstanding.dump_state(indent + 2u);
  INST_pipeline.dump_state(indent + 2u);
}


/* VCD dumping routines */

unsigned int MOD_mkTestDriver::dump_VCD_defs(unsigned int levels)
{
  vcd_write_scope_start(sim_hdl, inst_name);
  vcd_num = vcd_reserve_ids(sim_hdl, 21u);
  unsigned int num = vcd_num;
  for (unsigned int clk = 0u; clk < bk_num_clocks(sim_hdl); ++clk)
    vcd_add_clock_def(sim_hdl, this, bk_clock_name(sim_hdl, clk), bk_clock_vcd_num(sim_hdl, clk));
  vcd_write_def(sim_hdl, bk_clock_vcd_num(sim_hdl, __clk_handle_0), "CLK", 1u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "CAN_FIRE_RL_finish", 1u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "CAN_FIRE_RL_init", 1u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "CAN_FIRE_RL_pad", 1u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "CAN_FIRE_RL_read", 1u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "CAN_FIRE_RL_write", 1u);
  vcd_write_def(sim_hdl, num++, "RST_N", 1u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "TASK_fopen___d3", 32u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "TASK_fopen___d5", 32u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "WILL_FIRE_RL_finish", 1u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "WILL_FIRE_RL_init", 1u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "WILL_FIRE_RL_pad", 1u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "WILL_FIRE_RL_read", 1u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "WILL_FIRE_RL_write", 1u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "b__h978", 32u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "m_out___d32", 32u);
  vcd_set_clock(sim_hdl, num, __clk_handle_0);
  vcd_write_def(sim_hdl, num++, "x__h1135", 32u);
  num = INST_m_doneread.dump_VCD_defs(num);
  num = INST_m_in.dump_VCD_defs(num);
  num = INST_m_inited.dump_VCD_defs(num);
  num = INST_m_out.dump_VCD_defs(num);
  num = INST_m_outstanding.dump_VCD_defs(num);
  if (levels != 1u)
  {
    unsigned int l = levels == 0u ? 0u : levels - 1u;
    num = INST_pipeline.dump_VCD_defs(l);
  }
  vcd_write_scope_end(sim_hdl);
  return num;
}

void MOD_mkTestDriver::dump_VCD(tVCDDumpType dt, unsigned int levels, MOD_mkTestDriver &backing)
{
  vcd_defs(dt, backing);
  vcd_prims(dt, backing);
  if (levels != 1u)
    vcd_submodules(dt, levels - 1u, backing);
}

void MOD_mkTestDriver::vcd_defs(tVCDDumpType dt, MOD_mkTestDriver &backing)
{
  unsigned int num = vcd_num;
  if (dt == VCD_DUMP_XS)
  {
    vcd_write_x(sim_hdl, num++, 1u);
    vcd_write_x(sim_hdl, num++, 1u);
    vcd_write_x(sim_hdl, num++, 1u);
    vcd_write_x(sim_hdl, num++, 1u);
    vcd_write_x(sim_hdl, num++, 1u);
    vcd_write_x(sim_hdl, num++, 1u);
    vcd_write_x(sim_hdl, num++, 32u);
    vcd_write_x(sim_hdl, num++, 32u);
    vcd_write_x(sim_hdl, num++, 1u);
    vcd_write_x(sim_hdl, num++, 1u);
    vcd_write_x(sim_hdl, num++, 1u);
    vcd_write_x(sim_hdl, num++, 1u);
    vcd_write_x(sim_hdl, num++, 1u);
    vcd_write_x(sim_hdl, num++, 32u);
    vcd_write_x(sim_hdl, num++, 32u);
    vcd_write_x(sim_hdl, num++, 32u);
  }
  else
    if (dt == VCD_DUMP_CHANGES)
    {
      if ((backing.DEF_CAN_FIRE_RL_finish) != DEF_CAN_FIRE_RL_finish)
      {
	vcd_write_val(sim_hdl, num, DEF_CAN_FIRE_RL_finish, 1u);
	backing.DEF_CAN_FIRE_RL_finish = DEF_CAN_FIRE_RL_finish;
      }
      ++num;
      if ((backing.DEF_CAN_FIRE_RL_init) != DEF_CAN_FIRE_RL_init)
      {
	vcd_write_val(sim_hdl, num, DEF_CAN_FIRE_RL_init, 1u);
	backing.DEF_CAN_FIRE_RL_init = DEF_CAN_FIRE_RL_init;
      }
      ++num;
      if ((backing.DEF_CAN_FIRE_RL_pad) != DEF_CAN_FIRE_RL_pad)
      {
	vcd_write_val(sim_hdl, num, DEF_CAN_FIRE_RL_pad, 1u);
	backing.DEF_CAN_FIRE_RL_pad = DEF_CAN_FIRE_RL_pad;
      }
      ++num;
      if ((backing.DEF_CAN_FIRE_RL_read) != DEF_CAN_FIRE_RL_read)
      {
	vcd_write_val(sim_hdl, num, DEF_CAN_FIRE_RL_read, 1u);
	backing.DEF_CAN_FIRE_RL_read = DEF_CAN_FIRE_RL_read;
      }
      ++num;
      if ((backing.DEF_CAN_FIRE_RL_write) != DEF_CAN_FIRE_RL_write)
      {
	vcd_write_val(sim_hdl, num, DEF_CAN_FIRE_RL_write, 1u);
	backing.DEF_CAN_FIRE_RL_write = DEF_CAN_FIRE_RL_write;
      }
      ++num;
      if ((backing.PORT_RST_N) != PORT_RST_N)
      {
	vcd_write_val(sim_hdl, num, PORT_RST_N, 1u);
	backing.PORT_RST_N = PORT_RST_N;
      }
      ++num;
      if ((backing.DEF_TASK_fopen___d3) != DEF_TASK_fopen___d3)
      {
	vcd_write_val(sim_hdl, num, DEF_TASK_fopen___d3, 32u);
	backing.DEF_TASK_fopen___d3 = DEF_TASK_fopen___d3;
      }
      ++num;
      if ((backing.DEF_TASK_fopen___d5) != DEF_TASK_fopen___d5)
      {
	vcd_write_val(sim_hdl, num, DEF_TASK_fopen___d5, 32u);
	backing.DEF_TASK_fopen___d5 = DEF_TASK_fopen___d5;
      }
      ++num;
      if ((backing.DEF_WILL_FIRE_RL_finish) != DEF_WILL_FIRE_RL_finish)
      {
	vcd_write_val(sim_hdl, num, DEF_WILL_FIRE_RL_finish, 1u);
	backing.DEF_WILL_FIRE_RL_finish = DEF_WILL_FIRE_RL_finish;
      }
      ++num;
      if ((backing.DEF_WILL_FIRE_RL_init) != DEF_WILL_FIRE_RL_init)
      {
	vcd_write_val(sim_hdl, num, DEF_WILL_FIRE_RL_init, 1u);
	backing.DEF_WILL_FIRE_RL_init = DEF_WILL_FIRE_RL_init;
      }
      ++num;
      if ((backing.DEF_WILL_FIRE_RL_pad) != DEF_WILL_FIRE_RL_pad)
      {
	vcd_write_val(sim_hdl, num, DEF_WILL_FIRE_RL_pad, 1u);
	backing.DEF_WILL_FIRE_RL_pad = DEF_WILL_FIRE_RL_pad;
      }
      ++num;
      if ((backing.DEF_WILL_FIRE_RL_read) != DEF_WILL_FIRE_RL_read)
      {
	vcd_write_val(sim_hdl, num, DEF_WILL_FIRE_RL_read, 1u);
	backing.DEF_WILL_FIRE_RL_read = DEF_WILL_FIRE_RL_read;
      }
      ++num;
      if ((backing.DEF_WILL_FIRE_RL_write) != DEF_WILL_FIRE_RL_write)
      {
	vcd_write_val(sim_hdl, num, DEF_WILL_FIRE_RL_write, 1u);
	backing.DEF_WILL_FIRE_RL_write = DEF_WILL_FIRE_RL_write;
      }
      ++num;
      if ((backing.DEF_b__h978) != DEF_b__h978)
      {
	vcd_write_val(sim_hdl, num, DEF_b__h978, 32u);
	backing.DEF_b__h978 = DEF_b__h978;
      }
      ++num;
      if ((backing.DEF_m_out___d32) != DEF_m_out___d32)
      {
	vcd_write_val(sim_hdl, num, DEF_m_out___d32, 32u);
	backing.DEF_m_out___d32 = DEF_m_out___d32;
      }
      ++num;
      if ((backing.DEF_x__h1135) != DEF_x__h1135)
      {
	vcd_write_val(sim_hdl, num, DEF_x__h1135, 32u);
	backing.DEF_x__h1135 = DEF_x__h1135;
      }
      ++num;
    }
    else
    {
      vcd_write_val(sim_hdl, num++, DEF_CAN_FIRE_RL_finish, 1u);
      backing.DEF_CAN_FIRE_RL_finish = DEF_CAN_FIRE_RL_finish;
      vcd_write_val(sim_hdl, num++, DEF_CAN_FIRE_RL_init, 1u);
      backing.DEF_CAN_FIRE_RL_init = DEF_CAN_FIRE_RL_init;
      vcd_write_val(sim_hdl, num++, DEF_CAN_FIRE_RL_pad, 1u);
      backing.DEF_CAN_FIRE_RL_pad = DEF_CAN_FIRE_RL_pad;
      vcd_write_val(sim_hdl, num++, DEF_CAN_FIRE_RL_read, 1u);
      backing.DEF_CAN_FIRE_RL_read = DEF_CAN_FIRE_RL_read;
      vcd_write_val(sim_hdl, num++, DEF_CAN_FIRE_RL_write, 1u);
      backing.DEF_CAN_FIRE_RL_write = DEF_CAN_FIRE_RL_write;
      vcd_write_val(sim_hdl, num++, PORT_RST_N, 1u);
      backing.PORT_RST_N = PORT_RST_N;
      vcd_write_val(sim_hdl, num++, DEF_TASK_fopen___d3, 32u);
      backing.DEF_TASK_fopen___d3 = DEF_TASK_fopen___d3;
      vcd_write_val(sim_hdl, num++, DEF_TASK_fopen___d5, 32u);
      backing.DEF_TASK_fopen___d5 = DEF_TASK_fopen___d5;
      vcd_write_val(sim_hdl, num++, DEF_WILL_FIRE_RL_finish, 1u);
      backing.DEF_WILL_FIRE_RL_finish = DEF_WILL_FIRE_RL_finish;
      vcd_write_val(sim_hdl, num++, DEF_WILL_FIRE_RL_init, 1u);
      backing.DEF_WILL_FIRE_RL_init = DEF_WILL_FIRE_RL_init;
      vcd_write_val(sim_hdl, num++, DEF_WILL_FIRE_RL_pad, 1u);
      backing.DEF_WILL_FIRE_RL_pad = DEF_WILL_FIRE_RL_pad;
      vcd_write_val(sim_hdl, num++, DEF_WILL_FIRE_RL_read, 1u);
      backing.DEF_WILL_FIRE_RL_read = DEF_WILL_FIRE_RL_read;
      vcd_write_val(sim_hdl, num++, DEF_WILL_FIRE_RL_write, 1u);
      backing.DEF_WILL_FIRE_RL_write = DEF_WILL_FIRE_RL_write;
      vcd_write_val(sim_hdl, num++, DEF_b__h978, 32u);
      backing.DEF_b__h978 = DEF_b__h978;
      vcd_write_val(sim_hdl, num++, DEF_m_out___d32, 32u);
      backing.DEF_m_out___d32 = DEF_m_out___d32;
      vcd_write_val(sim_hdl, num++, DEF_x__h1135, 32u);
      backing.DEF_x__h1135 = DEF_x__h1135;
    }
}

void MOD_mkTestDriver::vcd_prims(tVCDDumpType dt, MOD_mkTestDriver &backing)
{
  INST_m_doneread.dump_VCD(dt, backing.INST_m_doneread);
  INST_m_in.dump_VCD(dt, backing.INST_m_in);
  INST_m_inited.dump_VCD(dt, backing.INST_m_inited);
  INST_m_out.dump_VCD(dt, backing.INST_m_out);
  INST_m_outstanding.dump_VCD(dt, backing.INST_m_outstanding);
}

void MOD_mkTestDriver::vcd_submodules(tVCDDumpType dt,
				      unsigned int levels,
				      MOD_mkTestDriver &backing)
{
  INST_pipeline.dump_VCD(dt, levels, backing.INST_pipeline);
}
