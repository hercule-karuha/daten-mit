import CacheTypes::*;
import MemTypes::*;
import Fifo::*;
import Types::*;
import Vector::*;
import MemUtil::*;
import Ehr::*;

typedef enum { Ready, StartMiss, SendFillReq, WaitFillResp } CacheStatus deriving (Eq, Bits);

module mkICache(WideMem wideMem, ICache cache);
    Reg#(CacheStatus) status <- mkReg(Ready);

    Vector#(CacheRows, Reg#(CacheLine)) dataArray <- replicateM(mkRegU);
    Vector#(CacheRows, Reg#(Maybe#(CacheTag))) tagArray <- replicateM(mkReg(Invalid));

    Fifo#(2, Data) hitQ <- mkCFFifo;
    Reg#(Addr) missReq <- mkRegU;

    function CacheIndex idxOf(Addr addr) = truncate(addr >> 6);
    function CacheTag tagOf(Addr addr) = truncateLSB(addr);
    function CacheWordSelect offsetOf(Addr addr) = truncate(addr >> 2);

    rule sendFillReq (status == SendFillReq);
        WideMemReq wideMemReq = toWideMemReq(MemReq{op: Ld, addr: missReq, data: ?, rid: ?});
        wideMemReq.write_en = 0;
        wideMem.req(wideMemReq);
        status <= WaitFillResp;
    endrule

    rule waitFillResp (status == WaitFillResp);
        let idx = idxOf(missReq);
        let tag = tagOf(missReq);
        let offset = offsetOf(missReq);

        let data <- wideMem.resp;
        tagArray[idx] <= tagged Valid tag;
        dataArray[idx] <= data;
        hitQ.enq(data[offset]);

        status <= Ready;
    endrule

    method Action req(Addr a) if (status == Ready);
        let idx = idxOf(a);
        let hit = False;
        let offset = offsetOf(a);
        if(tagArray[idx] matches tagged Valid .currTag
           &&& currTag == tagOf(a)) begin
            hit = True;
        end

        let cacheLine = dataArray[idx];
        if(hit) begin
            hitQ.enq(cacheLine[offset]);
        end
        else begin
            missReq <= a;
            status <= SendFillReq;
        end
    endmethod

    method ActionValue#(MemResp) resp;
        hitQ.deq;
        return hitQ.first;
    endmethod
endmodule