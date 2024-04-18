import CacheTypes::*;
import CMemTypes::*;
import Fifo::*;
import Types::*;
import Vector::*;

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

function WideMemReq toWideMemReq(MemReq req );
    Bit#(CacheLineWords) write_en = 0;
    CacheWordSelect wordsel = truncate( req.addr >> 2 );
    if( req.op == St ) begin
        write_en = 1 << wordsel;
    end
    Addr addr = req.addr;
    for( Integer i = 0 ; i < valueOf(TLog#(CacheLineBytes)) ; i = i+1 ) begin
        addr[i] = 0;
    end
    CacheLine data = replicate( req.data );

    return WideMemReq {
                write_en: write_en,
                addr: addr,
                data: data
            };
endfunction