import CacheTypes::*;
import Vector::*;
import MemTypes::*;
import Types::*;
import Fifo::*;
import Vector::*;
import MemUtil::*;
import RefTypes::*;

typedef enum{Ready, StartMiss, SendFillReq, WaitFillResp, Resp} CacheStatus deriving(Eq, Bits);
module mkDCache#(CoreID id)(MessageGet fromMem, MessagePut toMem, RefDMem refDMem, DCache ifc);
    Vector#(CacheRows, Reg#(CacheLine)) dataArray <- replicateM(mkRegU);
    Vector#(CacheRows, Reg#(CacheTag)) tagArray <- replicateM(mkRegU);
    Vector#(CacheRows, Reg#(Bool)) dirtyArray <- replicateM(mkReg(False));
    Vector#(CacheRows, Reg#(MSI)) stateArray <- replicateM(mkReg(I));

    Reg#(CacheStatus) status <- mkReg(Ready);

    Fifo#(1, MemReq) reqQ <- mkBypassFifo;
    Fifo#(2, Data) hitQ <- mkCFFifo;
    Reg#(MemReq) missReq <- mkRegU;

    rule doReq(status == Ready);
        let r = reqQ.first;
        reqQ.deq;
        let idx = getIndex(r.addr);
        let offset = getWordSelect(r.addr);
        let hit = tagArray[idx] == getTag(r.addr) && stateArray[idx] > I;

        if(hit) begin
            let cacheLine = dataArray[idx];
            if(r.op == Ld) begin
                hitQ.enq(cacheLine[offset]);
                refDMem.commit(r, tagged Valid(cacheLine), tagged Valid(cacheLine[offset]));
            end
            else if(r.op == St) begin
                if(stateArray[idx] == M) begin
                    cacheLine[offset] = r.data;
                    dataArray[idx] <= cacheLine;
                    refDMem.commit(r, Valid(dataArray[idx]), Invalid);
                end
                else begin 
                    missReq <= r; 
                    status <= SendFillReq;
                end
            end
        end
        else begin
            missReq <= r;
            status <= StartMiss;
        end
    endrule

    rule startMiss(status == StartMiss);
        let idx = getIndex(missReq.addr);
        let offset = getWordSelect(missReq.addr);
        if(stateArray[idx] != I) begin
            let d = stateArray[idx] == M ? tagged Valid dataArray[idx]: Invalid; 
            toMem.enq_resp(CacheMemResp{child: id, addr: {tagArray[idx], idx, offset, 0}, state: I, data: d});
            stateArray[idx] <= I;
        end
        status <= SendFillReq;
    endrule

    rule sendFillReq (status == SendFillReq);
        let upg = (missReq.op == Ld)? S : M;
        toMem.enq_req(CacheMemReq{child: id, addr: {getLineAddr(missReq.addr), 0}, state: upg}); 
        status <= WaitFillResp;
    endrule

    rule waitFillResp (status == WaitFillResp && fromMem.hasResp);
        let resp = fromMem.first matches tagged Resp .x ? x : ?;
        let idx = getIndex(missReq.addr);
        let tag = getTag(missReq.addr);

        CacheLine data = isValid(resp.data) ? fromMaybe(?, resp.data) : dataArray[idx];

        if(missReq.op == St) begin
            CacheLine ori_data = isValid(resp.data) ? fromMaybe(?, resp.data) : dataArray[idx];
            let offset = getWordSelect(missReq.addr);
            data[offset] = missReq.data;
            refDMem.commit(missReq, tagged Valid ori_data, Invalid);
        end

        dataArray[idx] <= data;
        stateArray[idx] <= resp.state;
        tagArray[idx] <= tag;
        fromMem.deq;
        status <= Resp;  
    endrule

    rule sendProc(status == Resp);
        let idx = getIndex(missReq.addr);
        if(missReq.op == Ld) begin
            let cacheLine = dataArray[idx];
            let offset = getWordSelect(missReq.addr);
            hitQ.enq(cacheLine[offset]); 
            refDMem.commit(missReq, tagged Valid cacheLine, tagged Valid cacheLine[offset]);
        end
        status <= Ready; 
    endrule

    rule dng(status != Resp && fromMem.hasReq);
        let req = fromMem.first matches tagged Req .x ? x : ?;
        $display("  core: %d dwongrade req come",id);
        let offset = getWordSelect(req.addr);
        let idx = getIndex(req.addr);
        let tag = getTag(req.addr);

        if (stateArray[idx] > req.state) begin
           Maybe#(CacheLine) data;
           if (stateArray[idx] == M)
                data = Valid(dataArray[idx]);
           else
                data = Invalid;
           let addr = {tag, idx, offset, 2'b0};
           toMem.enq_resp( CacheMemResp {child: id, addr: addr, state: req.state, data: data});

           stateArray[idx] <= req.state;
        end

        fromMem.deq;
    endrule


    method Action req(MemReq r) if (status == Ready);
        refDMem.issue(r);
        reqQ.enq(r);
    endmethod

    method ActionValue#(MemResp) resp;
        hitQ.deq;
        return hitQ.first;
    endmethod
endmodule