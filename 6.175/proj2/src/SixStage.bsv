import Types::*;
import ProcTypes::*;
import MemTypes::*;
import RFile::*;
import Decode::*;
import Exec::*;
import CsrFile::*;
import Fifo::*;
import Ehr::*;
import Btb::*;
import Scoreboard::*;
import Bht::*;
import GetPut::*;
import ClientServer::*;
import Memory::*;
import ICache::*;
import DCache::*;
import CacheTypes::*;
import WideMemInit::*;
import MemUtil::*;
import Vector::*;
import FShow::*;
import MemReqIDGen::*;
import RefTypes::*;
import MessageFifo::*;

typedef struct {
    Addr pc;
    Addr predPc;
	Bool eEpoch;
	Bool dEpoch;
} IF2D deriving (Bits, Eq);

typedef struct {
    Addr pc;
    Addr predPc;
    DecodedInst dInst;
	Bool eEpoch;
} D2RF deriving (Bits, Eq);

typedef struct {
    Addr pc;
    Addr predPc;
	DecodedInst dInst;
	Data rVal1;
    Data rVal2;
    Data csrVal;
    Bool eEpoch;
} RF2E deriving (Bits, Eq);

typedef struct {
	Addr pc;
	Addr nextPc;
} ExeRedirect deriving (Bits, Eq);

typedef struct {
	Addr pc;
	Addr nextPc;
	Bool eEpoch;
} DecRedirect deriving (Bits, Eq);

module mkCore#(CoreID id)(WideMem iMem, RefDMem refDMem, Core ifc);
    Ehr#(2, Addr) pcReg <- mkEhr(?);
    RFile rf <- mkRFile;
    CsrFile csrf <- mkCsrFile(id);

    MemReqIDGen memReqIDGen <- mkMemReqIDGen;
    ICache iCache <- mkICache(iMem);
    MessageFifo#(2) toParentQ <- mkMessageFifo;
	MessageFifo#(2) fromParentQ <- mkMessageFifo;
    DCache dCache <- mkDCache(id, toMessageGet(fromParentQ), toMessagePut(toParentQ), refDMem);

    Fifo#(6, IF2D) if2dFifo <- mkCFFifo;
	Fifo#(6, D2RF) d2rfFifo <- mkCFFifo;
	Fifo#(6, RF2E) rf2eFifo <- mkCFFifo;
	Fifo#(6, ExecInst) e2mFifo <- mkCFFifo;
	Fifo#(6, ExecInst) m2wbFifo <- mkCFFifo;

    Btb#(6) btb <- mkBtb;
	Bht#(8)	bht <- mkBHT;
    Scoreboard#(6) sb <- mkCFScoreboard;

    Reg#(Bool) exeEpoch <- mkReg(False);
	Reg#(Bool) decEpoch <- mkReg(False);

	Ehr#(2, Maybe#(ExeRedirect)) exeRedirect <- mkEhr(Invalid);
	Ehr#(2, Maybe#(DecRedirect)) decRedirect <- mkEhr(Invalid);

    rule doInstructionFetch(csrf.started);
		iCache.req(pcReg[0]);
		Addr predPc = btb.predPc(pcReg[0]);
		if2dFifo.enq(IF2D{pc: pcReg[0], predPc: predPc, eEpoch: exeEpoch, dEpoch: decEpoch});
		pcReg[0] <= predPc;
		$display("InstructionFetch: PC = %x", pcReg[0]);
	endrule

    rule doDecode(csrf.started);
		IF2D if2d = if2dFifo.first;
		Data inst <- iCache.resp;
		DecodedInst dInst = decode(inst);
		let newPc = dInst.iType == Br || dInst.iType == J ?
		bht.ppcDP(if2d.pc, dInst) : if2d.predPc;

		if (if2d.dEpoch == decEpoch) begin
			if (if2d.predPc != newPc) begin
				$display("Decode: find wrong path, Redirect PC = %x to %x", if2d.pc, newPc);
				decRedirect[0] <= Valid (DecRedirect {pc: if2d.pc, 
													  nextPc: newPc, 
													  eEpoch: if2d.eEpoch});
				d2rfFifo.enq(D2RF{pc: if2d.pc, predPc: newPc, dInst: dInst, eEpoch: if2d.eEpoch});
			end 
			else begin
				d2rfFifo.enq(D2RF{pc: if2d.pc, predPc: if2d.predPc, dInst: dInst, eEpoch: if2d.eEpoch});
			end
		end 
		else begin
			$display("Decode: Kill instruction: PC = %x", if2d.pc);
		end
		
		if2dFifo.deq;
		$display("Decode: PC = %x, inst = %x, expanded = ", if2d.pc, inst, showInst(inst));
	endrule

    rule doRegisterFetch(csrf.started);
		D2RF d2rf = d2rfFifo.first;

		DecodedInst dInst = d2rf.dInst;

		if(!sb.search1(dInst.src1) && !sb.search2(dInst.src2)) begin
			d2rfFifo.deq;
			sb.insert(dInst.dst);
			
			Data rVal1 = rf.rd1(fromMaybe(?, dInst.src1));
			Data rVal2 = rf.rd2(fromMaybe(?, dInst.src2));
			Data csrVal = csrf.rd(fromMaybe(?, dInst.csr));

			rf2eFifo.enq(RF2E{pc: d2rf.pc, predPc: d2rf.predPc, dInst: d2rf.dInst, 
			rVal1: rVal1, rVal2: rVal2, csrVal: csrVal, eEpoch: d2rf.eEpoch});

			$display("RegisterFetch: PC = %x", d2rf.pc);
		end
		else begin
			$display("RegisterFetch Stalled: PC = %x", d2rf.pc);
		end
	endrule

	rule doExecute(csrf.started);
		RF2E rf2e = rf2eFifo.first;
		rf2eFifo.deq;

		if(rf2e.eEpoch != exeEpoch) begin
			$display("Execute: Kill instruction: PC = %x", rf2e.pc);
			e2mFifo.enq(ExecInst{iType: Alu, dst:Invalid, csr:Invalid, data: ?,
			 addr: ?, mispredict:False, brTaken:False});
		end
		else begin
			ExecInst eInst = exec(rf2e.dInst, rf2e.rVal1, rf2e.rVal2, rf2e.pc, 
			rf2e.predPc, rf2e.csrVal);
			if(eInst.mispredict) begin
				$display("Execute finds misprediction: Redirect PC = %x to %x", rf2e.pc, eInst.addr);
				exeRedirect[0] <= Valid (ExeRedirect {
					pc: rf2e.pc,
					nextPc: eInst.addr
				});
			end
			else begin
				$display("Execute: PC = %x", rf2e.pc);
			end
			e2mFifo.enq(eInst);

			if(eInst.iType == Unsupported) begin
				$fwrite(stderr, "ERROR: Executing unsupported instruction at pc: %x. Exiting\n", rf2e.pc);
				$finish;
			end

			if(rf2e.dInst.iType == Br || rf2e.dInst.iType == J) begin
				bht.update(rf2e.pc, eInst.brTaken);
			end
		end
	endrule

	rule doMemory(csrf.started);
		e2mFifo.deq;
		ExecInst eInst = e2mFifo.first;
        if(eInst.iType == Ld) begin
			let rid <- memReqIDGen.getID;
			let r = MemReq{op: Ld, addr: eInst.addr, data: ?, rid: rid};
			dCache.req(r);
			$display("Exe: issue mem req ", fshow(r), "\n");
		end
		else if(eInst.iType == St) begin
			let rid <- memReqIDGen.getID;
			let r = MemReq{op: St, addr: eInst.addr, data: eInst.data, rid: rid};
			dCache.req(r);
			$display("Exe: issue mem req ", fshow(r), "\n");
		end
        else if(eInst.iType == Lr) begin
			let rid <- memReqIDGen.getID;
			let r = MemReq{op: Lr, addr: eInst.addr, data: ?, rid: rid};
			dCache.req(r);
			$display("Exe: issue mem req ", fshow(r), "\n");
		end
		else if(eInst.iType == Sc) begin
			let rid <- memReqIDGen.getID;
			let r = MemReq{op: Sc, addr: eInst.addr, data: eInst.data, rid: rid};
			dCache.req(r);
			$display("Exe: issue mem req ", fshow(r), "\n");
		end
		else if(eInst.iType == Fence) begin
			let rid <- memReqIDGen.getID;
			let r = MemReq{op: Fence, addr: ?, data: ?, rid: rid};
			dCache.req(r);
			$display("Exe: issue mem req ", fshow(r), "\n");
		end
		else begin
			$display("Exe: no mem op");
		end

		m2wbFifo.enq(eInst);
	endrule

	rule doWriteBack(csrf.started);
		m2wbFifo.deq;
		ExecInst eInst = m2wbFifo.first;

        if(eInst.iType == Ld || eInst.iType == Lr || eInst.iType == Sc) begin
			eInst.data <- dCache.resp;
		end
        if(isValid(eInst.dst)) begin
			rf.wr(fromMaybe(?, eInst.dst), eInst.data);
		end
        csrf.wr(eInst.iType == Csrw ? eInst.csr : Invalid, eInst.data);
        $display("%0t: core %d: WriteBack, eInst.data = %h", $time, id, eInst.data);
        sb.remove;
	endrule

	(* fire_when_enabled *)
	(* no_implicit_conditions *)
	rule cononicalizeRedirect(csrf.started);
		if(exeRedirect[1] matches tagged Valid .r) begin
			// fix mispred
			pcReg[1] <= r.nextPc;
			exeEpoch <= !exeEpoch; // flip epoch
			btb.update(r.pc, r.nextPc); // train BTB
			$display("Fetch: Mispredict, redirected by Execute");
		end
		else if(decRedirect[1] matches tagged Valid .r) begin
			if(r.eEpoch == exeEpoch) begin
				pcReg[1] <= r.nextPc;
				decEpoch <= !decEpoch;
				$display("Fetch: Mispredict, redirected by Decode");
			end
		end
		// reset EHR
		exeRedirect[1] <= Invalid;
		decRedirect[1] <= Invalid;
	endrule

    interface MessageGet toParent = toMessageGet(toParentQ);
	interface MessagePut fromParent = toMessagePut(fromParentQ);

    method ActionValue#(CpuToHostData) cpuToHost if(csrf.started);
        let ret <- csrf.cpuToHost;
        return ret;
    endmethod

	method Bool cpuToHostValid = csrf.cpuToHostValid;

    method Action hostToCpu(Bit#(32) startpc) if (!csrf.started);
        csrf.start;
        pcReg[0] <= startpc;
    endmethod
endmodule