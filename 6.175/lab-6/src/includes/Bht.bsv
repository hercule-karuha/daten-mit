import Vector::*;
import Types::*;
import ProcTypes::*;

interface Bht#(numeric type indexSize);
 method Addr ppcDP(Addr pc, Addr targetPC);
 method Action update(Addr pc, Bool taken);
endinterface

module mkBHT(Bht#(indexSize)) provisos(Add#(indexSize,a__,32));
    Vector#(TExp#(indexSize), Reg#(Bit#(2))) bhtArr <- replicateM(mkReg(2'b01));

    function Bit#(indexSize) getBhtIndex(Addr pc) = truncate(pc >> 2);
    function Addr computeTarget(Addr pc, Addr targetPC, Bool taken) = taken ? targetPC : pc + 4;
    function Bool extractDir(Bit#(2) bhtEntry);
        case (bhtEntry) matches
            2'b00 : return False;
            2'b01 : return False;
            2'b10 : return True;
            2'b11 : return True;
        endcase
    endfunction

    function Bit#(2) newDpBits(Bit#(2) dpBits, Bool taken);
        if(taken) begin
            case (dpBits) matches
              2'b00 : return 2'b01;
              2'b01 : return 2'b10;
              2'b10 : return 2'b11;
              2'b11 : return 2'b11;
            endcase
        end
        else begin
            case (dpBits) matches
               2'b00 : return 2'b00;
               2'b01 : return 2'b00;
               2'b10 : return 2'b01;
               2'b11 : return 2'b10;
             endcase
        end
    endfunction

    method Addr ppcDP(Addr pc, Addr targetPC);
        Bit#(indexSize) index = getBhtIndex(pc);
        let direction = extractDir(bhtArr[index]);
        return computeTarget(pc, targetPC, direction); 
    endmethod
    
    method Action update(Addr pc, Bool taken);
        Bit#(indexSize) index = getBhtIndex(pc);
        let dpBits = bhtArr[index];
        bhtArr[index] <= newDpBits(dpBits, taken); 
    endmethod
endmodule