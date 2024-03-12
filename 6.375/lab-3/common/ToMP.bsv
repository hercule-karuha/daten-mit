import ClientServer::*;
import FIFO::*;
import GetPut::*;

import FixedPoint::*;
import Vector::*;

import Complex::*;
import ComplexMP::*;
import Cordic::*;

typedef Server#(
    Vector#(nbins, Complex#(FixedPoint#(isize, fsize))),
    Vector#(nbins, ComplexMP#(isize, fsize, psize))
) ToMP#(numeric type nbins, numeric type isize, numeric type fsize, numeric type psize);


module mkToMP(ToMP#(nbins, isize, fsize, psize));
    FIFO#(Vector#(nbins, Complex#(FixedPoint#(isize, fsize)))) infifo <- mkFIFO();
    FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) outfifo <- mkFIFO();


    Vector#(nbins, ToMagnitudePhase#(isize, fsize, psize)) toMps <- replicateM(mkCordicToMagnitudePhase());
    Reg#(Bool) inputReady <- mkReg(False);

    rule getInput(!inputReady);
        Vector#(nbins, Complex#(FixedPoint#(isize, fsize))) inputs = infifo.first;
        infifo.deq;

        for(Integer i = 0; i < valueOf(nbins); i = i + 1) begin
            toMps[i].request.put(inputs[i]);
        end
        inputReady <= True;
    endrule

    rule getOutput(inputReady);
        Vector#(nbins, ComplexMP#(isize, fsize, psize)) outputs;
        for(Integer i = 0; i < valueOf(nbins); i = i + 1) begin
            outputs[i] <- toMps[i].response.get;
        end

        outfifo.enq(outputs);
        inputReady <= False;
    endrule

    interface Put request = toPut(infifo);
    interface Get response = toGet(outfifo);
endmodule