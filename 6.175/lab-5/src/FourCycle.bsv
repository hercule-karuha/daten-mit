// FourCycle.bsv
//
// This is a four cycle implementation of the RISC-V processor.

import Types::*;
import ProcTypes::*;
import CMemTypes::*;
import MemInit::*;
import RFile::*;
import DelayedMemory::*;
import Decode::*;
import Exec::*;
import CsrFile::*;
import Vector::*;
import FIFO::*;
import Ehr::*;
import GetPut::*;

typedef enum {
    Fetch,
    Decode,
    Execute,
    Writeback
} State deriving(Bits, Eq, FShow);

(* synthesize *)
module mkProc(Proc);
    Reg#(Addr) pc <- mkRegU;
    RFile      rf <- mkRFile;
    DelayedMemory  mem <- mkDelayedMemory;
    CsrFile  csrf <- mkCsrFile;

    Reg#(State) state <- mkReg(Fetch);

    Reg#(DecodedInst) d2e <- mkRegU;
    Reg#(ExecInst) e2w <- mkRegU;

    Bool memReady = mem.init.done();
    rule test (!memReady);
        let e = tagged InitDone;
        mem.init.request.put(e);
    endrule

    rule doFetch(csrf.started && state == Fetch);
        mem.req(MemReq{op: Ld, addr: pc, data: ?});
        state <= Decode;
    endrule

    rule doDecode(csrf.started && state == Decode);
        let inst <- mem.resp();
        d2e <= decode(inst);

        $display("pc: %h inst: (%h) expanded: ", pc, inst, showInst(inst));
        $fflush(stdout);

        state <= Execute;
    endrule

    rule doExecute(csrf.started && state == Execute);
        Data rVal1 = rf.rd1(fromMaybe(?, d2e.src1));
        Data rVal2 = rf.rd2(fromMaybe(?, d2e.src2));

        Data csrVal = csrf.rd(fromMaybe(?, d2e.csr));

        ExecInst eInst = exec(d2e, rVal1, rVal2, pc, ?, csrVal);

        if(eInst.iType == Ld) begin
            mem.req(MemReq{op: Ld, addr: eInst.addr, data: ?});
        end else if(eInst.iType == St) begin
            mem.req(MemReq{op: St, addr: eInst.addr, data: eInst.data});
        end

        if(eInst.iType == Unsupported) begin
            $fwrite(stderr, "ERROR: Executing unsupported instruction at pc: %x. Exiting\n", pc);
            $finish;
        end

        // These codes are checking invalid CSR index
        // you could uncomment it for debugging
        // 
        // check invalid CSR read
        if(eInst.iType == Csrr) begin
            let csrIdx = fromMaybe(0, eInst.csr);
            case(csrIdx)
                csrCycle, csrInstret, csrMhartid: begin
                    $display("CSRR reads 0x%0x", eInst.data);
                end
                default: begin
                    $fwrite(stderr, "ERROR: read invalid CSR 0x%0x. Exiting\n", csrIdx);
                    $finish;
                end
            endcase
        end
        // check invalid CSR write
        if(eInst.iType == Csrw) begin
            let csrIdx = fromMaybe(0, eInst.csr);
            if(csrIdx != csrMtohost) begin
                $fwrite(stderr, "ERROR: invalid CSR index = 0x%0x. Exiting\n", csrIdx);
                $finish;
            end
            else begin
                $display("CSRW writes 0x%0x", eInst.data);
            end
        end

        e2w <= eInst;
        state <= Writeback;
    endrule

    rule doWriteback(csrf.started && state == Writeback);
        if(isValid(e2w.dst)) begin
            if(e2w.iType == Ld) begin
                let memResp <- mem.resp();
                rf.wr(fromMaybe(?, e2w.dst), memResp);
            end
            else begin
                rf.wr(fromMaybe(?, e2w.dst), e2w.data);
            end
        end

        pc <= e2w.brTaken ? e2w.addr : pc + 4;
        csrf.wr(e2w.iType == Csrw ? e2w.csr : Invalid,  e2w.data);

        state <= Fetch;
    endrule
    

    method ActionValue#(CpuToHostData) cpuToHost;
        let ret <- csrf.cpuToHost;
        return ret;
    endmethod

    method Action hostToCpu(Bit#(32) startpc) if ( !csrf.started && memReady );
        csrf.start(0); // only 1 core, id = 0
        $display("Start at pc 200\n");
        $fflush(stdout);
        pc <= startpc;
    endmethod

    interface iMemInit = mem.init;
    interface dMemInit = mem.init;
endmodule