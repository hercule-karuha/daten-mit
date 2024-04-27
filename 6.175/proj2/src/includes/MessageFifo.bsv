import CacheTypes::*;
import Fifo::*;

module mkMessageFifo(MessageFifo#(n));
    Fifo#(n, CacheMemResp) respFifo <- mkCFFifo;
    Fifo#(n, CacheMemReq) reqFifo <- mkCFFifo;

    method Action enq_resp( CacheMemResp d );
        respFifo.enq(d);
    endmethod

    method Action enq_req( CacheMemReq d );
        reqFifo.enq(d);
    endmethod

    method Bool hasResp;
        return respFifo.notEmpty;
    endmethod

    method Bool hasReq;
        return reqFifo.notEmpty;
    endmethod

    method Bool notEmpty;
        return respFifo.notEmpty || reqFifo.notEmpty;
    endmethod

    method CacheMemMessage first if(respFifo.notEmpty || reqFifo.notEmpty);
        CacheMemMessage m = tagged Req CacheMemReq{child: 0, addr: 0, state : M};
        if(respFifo.notEmpty) begin
            m = tagged Resp respFifo.first;
        end
        else if(reqFifo.notEmpty) begin
            m = tagged Req reqFifo.first;
        end
        return m;
    endmethod

    method Action deq if(respFifo.notEmpty || reqFifo.notEmpty);
        if(respFifo.notEmpty) begin
            respFifo.deq;
        end
        else if(reqFifo.notEmpty) begin
            reqFifo.deq;
        end
    endmethod
endmodule