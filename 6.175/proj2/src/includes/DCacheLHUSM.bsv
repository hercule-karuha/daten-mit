import CacheTypes::*;
import Vector::*;
import FShow::*;
import MemTypes::*;
import Types::*;
import ProcTypes::*;
import Fifo::*;
import Ehr::*;
import RefTypes::*;
import StQ::*;


typedef enum{Ready, StartMiss, SendFillReq, WaitFillResp, Resp} CacheStatus deriving(Eq, Bits);
module mkDCacheStQLHUSM#(CoreID id)(MessageGet fromMem, MessagePut toMem, RefDMem refDMem, DCache ifc);
    Vector#(CacheRows, Reg#(CacheLine)) dataArray <- replicateM(mkRegU);
    Vector#(CacheRows, Reg#(CacheTag)) tagArray <- replicateM(mkRegU);
    Vector#(CacheRows, Reg#(MSI)) stateArray <- replicateM(mkReg(I));

    Reg#(CacheStatus) status <- mkReg(Ready);

    Fifo#(8, MemReq) reqQ <- mkBypassFifo;
    Fifo#(8, Data) hitQ <- mkCFFifo;
    Reg#(MemReq) missReq <- mkRegU;

    Reg#(Maybe#(CacheLineAddr)) linkAddr <- mkReg(Invalid);

    StQ#(StQSize) stq <- mkStQ;

    rule doLd(status == Ready && reqQ.first.op == Ld || (reqQ.first.op == Ld && missReq.op == St));
        let r = reqQ.first;
        reqQ.deq;
        let idx = getIndex(r.addr);
        let offset = getWordSelect(r.addr);
        let tag = getTag(r.addr);

        let x = stq.search(r.addr);
        if (isValid(x)) begin
            hitQ.enq(fromMaybe(?, x));
            refDMem.commit(r, Invalid, x);
        end
        else begin
            if (tagArray[idx] == tag && stateArray[idx] > I) begin
                hitQ.enq(dataArray[idx][offset]);
                refDMem.commit(r, Valid(dataArray[idx]),
                                Valid(dataArray[idx][offset]));
            end
            else if(status == Ready)begin
                missReq <= r;
                status <= StartMiss;
            end
        end
    endrule

    rule doSt(status == Ready && reqQ.first.op == St);
        reqQ.deq;
        stq.enq(reqQ.first);
    endrule

    rule mvStqToCache (status == Ready && !reqQ.notEmpty);
        let r <- stq.issue;
        let offset = getWordSelect(r.addr);
        let idx = getIndex(r.addr);
        let tag = getTag(r.addr);

        if (tagArray[idx] == tag && stateArray[idx] > I) begin
            if (stateArray[idx] == M) begin
                dataArray[idx][offset] <= r.data;
                refDMem.commit(r, Valid(dataArray[idx]), Invalid);
                stq.deq;
            end
            else begin
                missReq <= r;
                status <= SendFillReq;
            end
        end
        else begin
            missReq <= r;
            status <= StartMiss;
        end
    endrule

    rule doLr(status == Ready && reqQ.first.op == Lr && !stq.notEmpty);
        let r = reqQ.first;
        reqQ.deq;
        let idx = getIndex(r.addr);
        let offset = getWordSelect(r.addr);
        let tag = getTag(r.addr);

        let x = stq.search(r.addr);
        if (isValid(x)) begin
            hitQ.enq(fromMaybe(?, x));
            refDMem.commit(r, Invalid, x);
            linkAddr <= tagged Valid getLineAddr(r.addr);
        end
        else begin
            if (tagArray[idx] == tag && stateArray[idx] > I) begin
                hitQ.enq(dataArray[idx][offset]);
                refDMem.commit(r, Valid(dataArray[idx]),
                                Valid(dataArray[idx][offset]));
                linkAddr <= tagged Valid getLineAddr(r.addr);
            end
            else begin
                missReq <= r;
                status <= StartMiss;
            end
        end
    endrule

    rule doSc(status == Ready && reqQ.first.op == Sc && !stq.notEmpty);
        let r = reqQ.first;
        reqQ.deq;
        let offset = getWordSelect(r.addr);
        let idx = getIndex(r.addr);
        let tag = getTag(r.addr);
        if (linkAddr matches tagged Valid .la &&& la == getLineAddr(r.addr)) begin
            if (tagArray[idx] == tag && stateArray[idx] > I) begin
                if (stateArray[idx] == M) begin
                    hitQ.enq(scSucc);
                    dataArray[idx][offset] <= r.data;
                    refDMem.commit(r, Valid(dataArray[idx]), Valid(scSucc));
                    linkAddr <= Invalid;
                end
                else begin
                    missReq <= r;
                    status <= SendFillReq;
                end
            end
            else begin
                missReq <= r;
                status <= StartMiss;
            end
        end
        else begin
            hitQ.enq(scFail);
            refDMem.commit(r, Invalid, Valid(scFail));
            linkAddr <= Invalid;
        end
    endrule

    rule doFence(status == Ready && reqQ.first.op == Fence && !stq.notEmpty);
        reqQ.deq;
        refDMem.commit(reqQ.first, Invalid, Invalid);
    endrule

    rule startMiss(status == StartMiss);
        let idx = getIndex(missReq.addr);
        let offset = getWordSelect(missReq.addr);
        if(stateArray[idx] != I) begin
            let d = stateArray[idx] == M ? tagged Valid dataArray[idx]: Invalid; 
            toMem.enq_resp(CacheMemResp{child: id, addr: {tagArray[idx], idx, offset, 0}, state: I, data: d});
            if (isValid(linkAddr) && fromMaybe(?, linkAddr) == getLineAddr(missReq.addr)) begin
                linkAddr <= Invalid;
            end 
            stateArray[idx] <= I;
        end
        status <= SendFillReq;
    endrule

    rule sendFillReq (status == SendFillReq);
        let upg = (missReq.op == Ld || missReq.op == Lr)? S : M;
        toMem.enq_req(CacheMemReq{child: id, addr: {getLineAddr(missReq.addr), 0}, state: upg}); 
        status <= WaitFillResp;
    endrule

    rule waitFillResp (status == WaitFillResp && fromMem.hasResp);
        let resp = fromMem.first matches tagged Resp .x ? x : ?;
        let idx = getIndex(missReq.addr);
        let tag = getTag(missReq.addr);
        let offset = getWordSelect(missReq.addr);
        
        CacheLine data = isValid(resp.data) ? fromMaybe(?, resp.data) : dataArray[idx];
        CacheLine ori_data = isValid(resp.data) ? fromMaybe(?, resp.data) : dataArray[idx];
        if(missReq.op == St) begin
            data[offset] = missReq.data;
            refDMem.commit(missReq, tagged Valid ori_data, Invalid);
            stq.deq;
        end
        else if (missReq.op == Sc) begin
            if (isValid(linkAddr) && fromMaybe(?, linkAddr) == getLineAddr(missReq.addr)) begin
                refDMem.commit(missReq, tagged Valid ori_data, Valid(scSucc));
                data[offset] = missReq.data;
                hitQ.enq(scSucc);
            end
            else begin
                hitQ.enq(scFail);
                refDMem.commit(missReq, Invalid, Valid(scFail));
            end
            linkAddr <= Invalid;
        end

        dataArray[idx] <= data;
        stateArray[idx] <= resp.state;
        tagArray[idx] <= tag;
        fromMem.deq;
        status <= Resp;  
    endrule

    rule sendProc(status == Resp);
        let idx = getIndex(missReq.addr);
        if(missReq.op == Ld || missReq.op == Lr) begin
            let cacheLine = dataArray[idx];
            let offset = getWordSelect(missReq.addr);
            hitQ.enq(cacheLine[offset]); 
            refDMem.commit(missReq, tagged Valid cacheLine, tagged Valid cacheLine[offset]);
            if (missReq.op == Lr) begin
                linkAddr <= tagged Valid getLineAddr(missReq.addr);
            end
        end
        status <= Ready; 
    endrule

    rule dng(status != Resp && fromMem.hasReq && !fromMem.hasResp);
        let req = fromMem.first matches tagged Req .x ? x : ?;
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
           if(isValid(linkAddr) && fromMaybe(?, linkAddr) == getLineAddr(req.addr) 
            && req.state == I) begin
                linkAddr <= Invalid;
           end 
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

