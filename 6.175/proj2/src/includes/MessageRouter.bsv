import CacheTypes::*;
import Vector::*;
import MemTypes::*;
import Types::*;



module mkMessageRouter(
  Vector#(CoreNum, MessageGet) c2r, Vector#(CoreNum, MessagePut) r2c, 
  MessageGet m2r, MessagePut r2m,
  Empty ifc 
);
    Bool has_core_resp = False;
    for(Integer i = 0; i < valueOf(CoreNum); i = i + 1) begin
        if(c2r[i].hasResp) begin
            has_core_resp = True;
        end
    end

    Bool has_core_req = False;
    for(Integer i = 0; i < valueOf(CoreNum); i = i + 1) begin
        if(c2r[i].hasReq) begin
            has_core_req = True;
        end
    end

    rule c2m(has_core_resp || has_core_req);
        CacheMemMessage m = tagged Req CacheMemReq{child: 0, addr: 0, state : M};
        Integer index = 0;
        if(has_core_resp) begin
            for(Integer i = 0; i < valueOf(CoreNum); i = i + 1) begin
                if(c2r[i].hasResp) begin
                    index = i;
                    m = c2r[i].first;
                end
            end
            c2r[index].deq;
            if(m matches tagged Resp .resp) begin
                r2m.enq_resp(resp);
            end
        end
        else if(has_core_req) begin
            for(Integer i = 0; i < valueOf(CoreNum); i = i + 1) begin
                if(c2r[i].hasReq) begin
                    index = i;
                    m = c2r[i].first;
                end
            end
            c2r[index].deq;
            if(m matches tagged Req .req) begin
                r2m.enq_req(req);
            end
        end
    endrule

    rule m2c(m2r.notEmpty);
        if(m2r.hasResp) begin
            let m = m2r.first;
            m2r.deq;
            if(m matches tagged Resp .resp) begin
                r2c[resp.child].enq_resp(resp);
            end
        end
        else if(m2r.hasReq) begin
            let m = m2r.first;
            m2r.deq;
            if(m matches tagged Req .req) begin
                r2c[req.child].enq_req(req);
            end
        end
    endrule
endmodule