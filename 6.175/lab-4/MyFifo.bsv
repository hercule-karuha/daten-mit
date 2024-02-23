import Ehr::*;
import Vector::*;

//////////////////
// Fifo interface 

interface Fifo#(numeric type n, type t);
    method Bool notFull;
    method Action enq(t x);
    method Bool notEmpty;
    method Action deq;
    method t first;
    method Action clear;
endinterface

/////////////////
// Conflict FIFO

// Exercise 1
module mkMyConflictFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
    Vector#(n, Reg#(t)) data <- replicateM(mkRegU);
    Reg#(Bit#(TLog#(n))) enqP <- mkReg(0);
    Reg#(Bit#(TLog#(n))) deqP <- mkReg(0);
    Reg#(Bool) full <- mkReg(False);
    Reg#(Bool) empty <- mkReg(True);

    method Bool notFull;
        return !full;
    endmethod

    method Action enq(t x) if(!full);
        data[enqP] <= x;

        enqP <= enqP == fromInteger(valueOf(TSub#(n, 1))) ? 0 : enqP + 1;
        empty <= False;
        

        if((deqP == 0 && enqP == fromInteger(valueOf(TSub#(n, 1)))) || enqP == deqP - 1) begin
            full <= True;
        end
    endmethod

    method Bool notEmpty;
        return !empty;
    endmethod
    
    method Action deq if(!empty);
        deqP <= deqP == fromInteger(valueOf(TSub#(n, 1))) ? 0 : deqP + 1;
        full <= False;

        if((enqP == 0 && deqP == fromInteger(valueOf(TSub#(n, 1)))) || deqP == enqP - 1) begin
            empty <= True;
        end
    endmethod

    method t first if(!empty);
        return data[deqP];
    endmethod
    
    method Action clear;
        enqP <= 0;
        deqP <= 0;
        empty <= True;
        full <= False;
    endmethod

endmodule


//Exercise 2
// Pipeline FIFO
// Intended schedule:
//      {notEmpty, first, deq} < {notFull, enq} < clear
module mkMyPipelineFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
    Vector#(n, Reg#(t)) data <- replicateM(mkRegU);
    Ehr#(3, Bit#(TLog#(n))) enqP <- mkEhr(0);
    Ehr#(3, Bit#(TLog#(n))) deqP <- mkEhr(0);
    Ehr#(3, Bool) full <- mkEhr(False);
    Ehr#(3, Bool) empty <- mkEhr(True);
    
    Bit#(TLog#(n)) max_index = fromInteger(valueOf(TSub#(n,1)));

    method Bool notFull;
        return !full[1];
    endmethod

    method Action enq(t x) if(!full[1]);
        let next_enqP = enqP[1] == max_index ? 0 : enqP[1] + 1;
        data[enqP[1]] <= x;
        enqP[1] <= next_enqP;
        empty[1] <= False;
        full[1] <= next_enqP == deqP[1] ? True : False;
    endmethod

    method Bool notEmpty;
        return !empty[0];
    endmethod

    method Action deq if(!empty[0]);
        let next_deqP = deqP[0] == max_index ? 0 : deqP[0] + 1;
        deqP[0] <= next_deqP;
        full[0] <= False;
        empty[0] <= next_deqP == enqP[0] ? True : False;
    endmethod

    method t first if(!empty[0]);
        return data[deqP[0]];
    endmethod

    method Action clear;
        enqP[2] <= 0;
        deqP[2] <= 0;
        empty[2] <= True;
        full[2] <= False;
    endmethod
endmodule

// Exercise 2
// Bypass FIFO
// Intended schedule:
//      {notFull, enq} < {notEmpty, first, deq} < clear
module mkMyBypassFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
    Vector#(n, Ehr#(2, t)) data <- replicateM(mkEhr(?));
    Ehr#(3, Bit#(TLog#(n))) enqP <- mkEhr(0);
    Ehr#(3, Bit#(TLog#(n))) deqP <- mkEhr(0);
    Ehr#(3, Bool) full <- mkEhr(False);
    Ehr#(3, Bool) empty <- mkEhr(True);
    
    Bit#(TLog#(n)) max_index = fromInteger(valueOf(TSub#(n,1)));

    method Bool notFull;
        return !full[0];
    endmethod

    method Action enq(t x) if(!full[0]);
        let next_enqP = enqP[0] == max_index ? 0 : enqP[0] + 1;
        data[enqP[0]][0] <= x;
        enqP[0] <= next_enqP;
        empty[0] <= False;
        full[0] <= next_enqP == deqP[0] ? True : False;
    endmethod

    method Bool notEmpty;
        return !empty[1];
    endmethod

    method Action deq if(!empty[1]);
        let next_deqP = deqP[1] == max_index ? 0 : deqP[1] + 1;
        deqP[1] <= next_deqP;
        full[1] <= False;
        empty[1] <= next_deqP == enqP[1] ? True : False;
    endmethod

    method t first if(!empty[1]);
        return data[deqP[1]][1];
    endmethod

    method Action clear;
        enqP[2] <= 0;
        deqP[2] <= 0;
        empty[2] <= True;
        full[2] <= False;
    endmethod
endmodule


// Exercise 3
// Exercise 4
// Conflict-free fifo
// Intended schedule:
//      {notFull, enq} CF {notEmpty, first, deq}
//      {notFull, enq, notEmpty, first, deq} < clear
module mkMyCFFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
endmodule

