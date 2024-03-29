import Types::*;
import ProcTypes::*;
import CMemTypes::*;
import RFile::*;
import IMemory::*;
import DMemory::*;
import Decode::*;
import Exec::*;
import CsrFile::*;
import Vector::*;
import MyFifo::*;
import Ehr::*;
import GetPut::*;

typedef enum {Fetch, Execute} State deriving (Bits, Eq);

(* synthesize *)
module mkProc(Proc);
    Reg#(Addr) pc <- mkRegU;
    RFile      rf <- mkRFile;
    DMemory  dMem <- mkDMemory;
    CsrFile  csrf <- mkCsrFile;

    Reg#(State) state <- mkReg(Fetch);
    Reg#(Data) f2d <- mkRegU;

    Bool memReady = dMem.init.done();
    rule test (!memReady);
        let e = tagged InitDone;
        dMem.init.request.put(e);
    endrule

    rule doFetch(csrf.started && state == Fetch);
        let inst <- dMem.req(MemReq{op: Ld, addr: pc, data: ?});

        $display("pc: %h inst: (%h) expanded: ", pc, inst, showInst(inst));
        $fflush(stdout);

        f2d <= inst;
        state <= Execute;
    endrule

    rule doExecute(csrf.started && state == Execute);
        let inst = f2d;
        DecodedInst dInst = decode(inst);

        Data rVal1 = rf.rd1(fromMaybe(?, dInst.src1));
        Data rVal2 = rf.rd2(fromMaybe(?, dInst.src2));

        Data csrVal = csrf.rd(fromMaybe(?, dInst.csr));

        ExecInst eInst = exec(dInst, rVal1, rVal2, pc, ?, csrVal);  

        if(eInst.iType == Ld) begin
            eInst.data <- dMem.req(MemReq{op: Ld, addr: eInst.addr, data: ?});
        end else if(eInst.iType == St) begin
            let d <- dMem.req(MemReq{op: St, addr: eInst.addr, data: eInst.data});
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

        if(isValid(eInst.dst)) begin
            rf.wr(fromMaybe(?, eInst.dst), eInst.data);
        end

        pc <= eInst.brTaken ? eInst.addr : pc + 4;

        csrf.wr(eInst.iType == Csrw ? eInst.csr : Invalid, eInst.data);

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


    interface dMemInit = dMem.init;
endmodule