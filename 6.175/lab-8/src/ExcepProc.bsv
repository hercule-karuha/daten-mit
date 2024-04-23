// OneCycle.bsv
//
// This is a one cycle implementation of the RISC-V processor.

import Types::*;
import ProcTypes::*;
import RFile::*;
import MemTypes::*;
import IMemory::*;
import DMemory::*;
import Decode::*;
import Exec::*;
import CsrFile::*;
import Vector::*;
import Fifo::*;
import Ehr::*;
import GetPut::*;

(* synthesize *)
module mkProc(Proc);
    Reg#(Addr) pc <- mkRegU;
    RFile      rf <- mkRFile;
    IMemory  iMem <- mkIMemory;
    DMemory  dMem <- mkDMemory;
    CsrFile  csrf <- mkCsrFile;

    Bool memReady = iMem.init.done() && dMem.init.done();
    rule test (!memReady);
        let e = tagged InitDone;
        iMem.init.request.put(e);
        dMem.init.request.put(e);
    endrule
    rule doProc(csrf.started);
        Data inst = iMem.req(pc);

        // decode
        let inUserMode = csrf.getMstatus[2:1] == 2'b00;
        DecodedInst dInst = decode(inst, inUserMode);

        // read general purpose register values 
        Data rVal1 = rf.rd1(fromMaybe(?, dInst.src1));
        Data rVal2 = rf.rd2(fromMaybe(?, dInst.src2));

        // read CSR values (for CSRR inst)
        Data csrVal = csrf.rd(fromMaybe(?, dInst.csr));

        // execute
        ExecInst eInst = exec(dInst, rVal1, rVal2, pc, ?, csrVal);  
        // The fifth argument above is the predicted pc, to detect if it was mispredicted. 
        // Since there is no branch prediction, this field is sent with a random value

        // memory
        if(eInst.iType == Ld) begin
            eInst.data <- dMem.req(MemReq{op: Ld, addr: eInst.addr, data: ?});
        end else if(eInst.iType == St) begin
            let d <- dMem.req(MemReq{op: St, addr: eInst.addr, data: eInst.data});
        end

        // commit

        // trace - print the instruction
        $display("pc: %h inst: (%h) expanded: ", pc, inst, showInst(inst));
        $fflush(stdout);

        // check unsupported instruction at commit time. Exiting
        if(eInst.iType == NoPermission) begin
            $fwrite(stderr, "ERROR: Executing NoPermission instruction at pc: %x. Exiting\n", pc);
            $finish;
        end
        else if(eInst.iType == Unsupported) begin
            $display("Unsupported  instruction at pc: %x", pc);
            let curStatus = csrf.getMstatus;
            let status = curStatus << 3;
            status[2:1] = 2'b11;
            status[0] = 0;
            csrf.startExcep(pc, excepUnsupport, status);
            pc <= csrf.getMtvec;
        end
        else if(eInst.iType == ECall) begin
            let curStatus = csrf.getMstatus;
            let status = curStatus << 3;
            status[2:1] = 2'b11;
            status[0] = 0;
            csrf.startExcep(pc, excepUserECall, status);
            pc <= csrf.getMtvec;
        end
        else if(eInst.iType == ERet) begin
            let curStatus = csrf.getMstatus;
            let status = (curStatus >> 3);
            csrf.eret(status);
            pc <= csrf.getMepc;
        end
        else begin
            // write back to reg file
            if(isValid(eInst.dst)) begin
                rf.wr(fromMaybe(?, eInst.dst), eInst.data);
            end
            // update the pc depending on whether the branch is taken or not
            pc <= eInst.brTaken ? eInst.addr : pc + 4;
            // CSR write for sending data to host & stats
            csrf.wr(eInst.iType == Csrrw ? eInst.csr : Invalid, eInst.data);
        end


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

    interface iMemInit = iMem.init;
    interface dMemInit = dMem.init;
endmodule

