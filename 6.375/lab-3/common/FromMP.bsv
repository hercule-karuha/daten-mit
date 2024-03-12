import ClientServer::*;
import FIFO::*;
import GetPut::*;

import FixedPoint::*;
import Vector::*;

import Complex::*;
import ComplexMP::*;
import Cordic::*;


typedef Server#(
    Vector#(nbins, ComplexMP#(isize, fsize, psize)),
    Vector#(nbins, Complex#(FixedPoint#(isize, fsize)))
) FromMP#(numeric type nbins, numeric type isize, numeric type fsize, numeric type psize);



module mkFromMP(FromMP#(nbins, isize, fsize, psize));
    FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) infifo <- mkFIFO();
    FIFO#(Vector#(nbins, Complex#(FixedPoint#(isize, fsize)))) outfifo <- mkFIFO();

    Vector#(nbins, FromMagnitudePhase#(isize, fsize, psize)) fromMps <- replicateM(mkCordicFromMagnitudePhase());
    Reg#(Bool) inputReady <- mkReg(False);

    rule getInput(!inputReady);
        Vector#(nbins, ComplexMP#(isize, fsize, psize)) inputs = infifo.first;
        infifo.deq;
        for(Integer i = 0; i < valueOf(nbins); i = i + 1) begin
            fromMps[i].request.put(inputs[i]);
        end
        inputReady <= True;
    endrule

    rule getOutput(inputReady);
        Vector#(nbins, Complex#(FixedPoint#(isize, fsize))) outputs;
        for(Integer i = 0; i < valueOf(nbins); i = i + 1) begin
            outputs[i] <- fromMps[i].response.get;
        end

        outfifo.enq(outputs);
        inputReady <= False;
    endrule

    interface Put request = toPut(infifo);
    interface Get response = toGet(outfifo);
endmodule