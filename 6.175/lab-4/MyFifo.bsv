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
    Reg#(Bit#(TLog#(n))) enqp <- mkReg(0);
    Reg#(Bit#(TLog#(n))) deqp <- mkReg(0);
    Reg#(Bool) full <- mkReg(False);
    Reg#(Bool) empty <- mkReg(True);

    method Bool notFull;
        return !full;
    endmethod

    method Action enq(t x) if(!full);
        data[enqp] <= x;

        enqp <= enqp == fromInteger(valueOf(TSub#(n, 1))) ? 0 : enqp + 1;
        empty <= False;
        

        if((deqp == 0 && enqp == fromInteger(valueOf(TSub#(n, 1)))) || enqp == deqp - 1) begin
            full <= True;
        end
    endmethod

    method Bool notEmpty;
        return !empty;
    endmethod
    
    method Action deq if(!empty);
        deqp <= deqp == fromInteger(valueOf(TSub#(n, 1))) ? 0 : deqp + 1;
        full <= False;

        if((enqp == 0 && deqp == fromInteger(valueOf(TSub#(n, 1)))) || deqp == enqp - 1) begin
            empty <= True;
        end
    endmethod

    method t first if(!empty);
        return data[deqp];
    endmethod
    
    method Action clear;
        enqp <= 0;
        deqp <= 0;
        empty <= True;
        full <= False;
    endmethod

endmodule


//Exercise 2
// Pipeline FIFO
// Intended schedule:
//      {notEmpty, first, deq} < {notFull, enq} < clear
module mkMyPipelineFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
endmodule

// Exercise 2
// Bypass FIFO
// Intended schedule:
//      {notFull, enq} < {notEmpty, first, deq} < clear
module mkMyBypassFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
endmodule


// Exercise 3
// Exercise 4
// Conflict-free fifo
// Intended schedule:
//      {notFull, enq} CF {notEmpty, first, deq}
//      {notFull, enq, notEmpty, first, deq} < clear
module mkMyCFFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
endmodule

