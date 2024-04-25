import CacheTypes::*;
import CMemTypes::*;
import Fifo::*;
import Types::*;
import Vector::*;
import MemUtil::*;

module mkTranslator(WideMem wideMem, Cache cache);
    Fifo#(2, MemReq) reqFifo <- mkCFFifo;

    method Action req(MemReq r);
        if ( r.op == Ld ) reqFifo.enq(r);
        wideMem.req(toWideMemReq(r));
    endmethod

    method ActionValue#(MemResp) resp;
        let req = reqFifo.first;
        reqFifo.deq;

        let cacheLine <- wideMem.resp;
        CacheWordSelect offset = truncate(req.addr >> 2);
        
        return cacheLine[offset];
    endmethod
endmodule

typedef enum { Ready, StartMiss, SendFillReq, WaitFillResp } CacheStatus deriving (Eq, Bits);

module mkICache(WideMem wideMem, ICache cache);
    Reg#(CacheStatus) status <- mkReg(Ready);

    Vector#(CacheRows, Reg#(CacheLine)) dataArray <- replicateM(mkRegU);
    Vector#(CacheRows, Reg#(Maybe#(CacheTag))) tagArray <- replicateM(mkReg(Invalid));

    Fifo#(2, Data) hitQ <- mkCFFifo;
    Reg#(MemReq) missReq <- mkRegU;

    function CacheIndex idxOf(Addr addr) = truncate(addr >> 6);
    function CacheTag tagOf(Addr addr) = truncateLSB(addr);
    function CacheWordSelect offsetOf(Addr addr) = truncate(addr >> 2);

    rule sendFillReq (status == SendFillReq);
        WideMemReq wideMemReq = toWideMemReq(missReq);
        wideMemReq.write_en = 0;
        wideMem.req(wideMemReq);
        status <= WaitFillResp;
    endrule

    rule waitFillResp (status == WaitFillResp);
        let idx = idxOf(missReq.addr);
        let tag = tagOf(missReq.addr);
        let offset = offsetOf(missReq.addr);

        let data <- wideMem.resp;
        tagArray[idx] <= tagged Valid tag;
        dataArray[idx] <= data;
        hitQ.enq(data[offset]);

        status <= Ready;
    endrule

    method Action req(MemReq r) if (status == Ready);
        let idx = idxOf(r.addr);
        let hit = False;
        let offset = offsetOf(r.addr);
        if(tagArray[idx] matches tagged Valid .currTag
           &&& currTag == tagOf(r.addr)) begin
            hit = True;
        end

        let cacheLine = dataArray[idx];
        if(hit) begin
            hitQ.enq(cacheLine[offset]);
        end
        else begin
            missReq <= r;
            status <= SendFillReq;
        end
    endmethod

    method ActionValue#(MemResp) resp;
        hitQ.deq;
        return hitQ.first;
    endmethod
endmodule

module mkDCache(WideMem wideMem, DCache cache);
    Reg#(CacheStatus) status <- mkReg(Ready);

    Vector#(CacheRows, Reg#(CacheLine)) dataArray <- replicateM(mkRegU);
    Vector#(CacheRows, Reg#(Maybe#(CacheTag))) tagArray <- replicateM(mkReg(Invalid));
    Vector#(CacheRows, Reg#(Bool)) dirtyArray <- replicateM(mkReg(False));

    Fifo#(1, MemReq) reqQ <- mkBypassFifo;
    Fifo#(2, Data) hitQ <- mkCFFifo;
    Reg#(MemReq) missReq <- mkRegU;

    function CacheIndex idxOf(Addr addr) = truncate(addr >> 6);
    function CacheTag tagOf(Addr addr) = truncateLSB(addr);
    function CacheWordSelect offsetOf(Addr addr) = truncate(addr >> 2);

    rule doReq(status == Ready);
        let r = reqQ.first;
        reqQ.deq;
        let idx = idxOf(r.addr);
        let hit = False;
        let offset = offsetOf(r.addr);
        if(tagArray[idx] matches tagged Valid .currTag
           &&& currTag == tagOf(r.addr)) begin
            hit = True;
        end
        if(r.op == Ld) begin
            let cacheLine = dataArray[idx];
            if(hit) begin
                hitQ.enq(cacheLine[offset]);
            end
            else begin
                missReq <= r;
                status <= StartMiss;
            end
        end
        else begin
            if(hit) begin
                let cacheLine = dataArray[idx];
                cacheLine[offset] = r.data;
        	    dataArray[idx] <= cacheLine;
                dirtyArray[idx] <= True;
            end
            else begin
                wideMem.req(toWideMemReq(r));
            end
        end
    endrule

    rule startMiss(status == StartMiss);
        let idx = idxOf(missReq.addr);
        let dirty = dirtyArray[idx];
        let tag = tagArray[idx];
        if(isValid(tag) && dirty) begin
            let addr = {fromMaybe(?, tag), idx, 6'b0};
            let data = dataArray[idx];
            wideMem.req(WideMemReq{write_en: '1, addr: addr, data: data});
        end
        status <= SendFillReq;
    endrule

    rule sendFillReq (status == SendFillReq);
        WideMemReq wideMemReq = toWideMemReq(missReq);
        wideMemReq.write_en = 0;
        wideMem.req(wideMemReq);
        status <= WaitFillResp;
    endrule

    rule waitFillResp (status == WaitFillResp);
        let idx = idxOf(missReq.addr);
        let tag = tagOf(missReq.addr);
        let offset = offsetOf(missReq.addr);

        let data <- wideMem.resp;
        tagArray[idx] <= tagged Valid tag;
        dirtyArray[idx] <= False;
        dataArray[idx] <= data;
        hitQ.enq(data[offset]);

        status <= Ready;
    endrule

    method Action req(MemReq r) if (status == Ready);
        reqQ.enq(r);
    endmethod

    method ActionValue#(MemResp) resp;
        hitQ.deq;
        return hitQ.first;
    endmethod
endmodule