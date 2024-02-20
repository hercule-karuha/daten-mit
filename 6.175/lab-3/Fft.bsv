import Vector::*;
import Complex::*;

import FftCommon::*;
import Fifo::*;
import FIFOF::*;

interface Fft;
    method Action enq(Vector#(FftPoints, ComplexData) in);
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
endinterface


(* synthesize *)
module mkFftCombinational(Fft);
    FIFOF#(Vector#(FftPoints, ComplexData)) inFifo <- mkFIFOF;
    FIFOF#(Vector#(FftPoints, ComplexData)) outFifo <- mkFIFOF;
    Vector#(NumStages, Vector#(BflysPerStage, Bfly4)) bfly <- replicateM(replicateM(mkBfly4));

    function Vector#(FftPoints, ComplexData) stage_f(StageIdx stage, Vector#(FftPoints, ComplexData) stage_in);
        Vector#(FftPoints, ComplexData) stage_temp, stage_out;
        for (FftIdx i = 0; i < fromInteger(valueOf(BflysPerStage)); i = i + 1)  begin
            FftIdx idx = i * 4;
            Vector#(4, ComplexData) x;
            Vector#(4, ComplexData) twid;
            for (FftIdx j = 0; j < 4; j = j + 1 ) begin
                x[j] = stage_in[idx+j];
                twid[j] = getTwiddle(stage, idx+j);
            end
            let y = bfly[stage][i].bfly4(twid, x);

            for(FftIdx j = 0; j < 4; j = j + 1 ) begin
                stage_temp[idx+j] = y[j];
            end
        end

        stage_out = permute(stage_temp);

        return stage_out;
    endfunction
  
    rule doFft;
            inFifo.deq;
            Vector#(4, Vector#(FftPoints, ComplexData)) stage_data;
            stage_data[0] = inFifo.first;
      
            for (StageIdx stage = 0; stage < 3; stage = stage + 1) begin
                stage_data[stage+1] = stage_f(stage, stage_data[stage]);
            end
            outFifo.enq(stage_data[3]);
    endrule
    
    method Action enq(Vector#(FftPoints, ComplexData) in);
        inFifo.enq(in);
    endmethod
  
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
        outFifo.deq;
        return outFifo.first;
    endmethod
endmodule

// Exercise 2
(* synthesize *)
module mkFftInelasticPipeline(Fft);
    FIFOF#(Vector#(FftPoints, ComplexData)) inFifo <- mkFIFOF;
    FIFOF#(Vector#(FftPoints, ComplexData)) outFifo <- mkFIFOF;
    Reg #(Maybe#(Vector#(FftPoints, ComplexData))) sReg1 <- mkRegU;
    Reg #(Maybe#(Vector#(FftPoints, ComplexData))) sReg2 <- mkRegU;
    Vector#(NumStages, Vector#(BflysPerStage, Bfly4)) bfly <- replicateM(replicateM(mkBfly4));

    function Vector#(FftPoints, ComplexData) stage_f(StageIdx stage, Vector#(FftPoints, ComplexData) stage_in);
        Vector#(FftPoints, ComplexData) stage_temp, stage_out;
        for (FftIdx i = 0; i < fromInteger(valueOf(BflysPerStage)); i = i + 1)  begin
            FftIdx idx = i * 4;
            Vector#(4, ComplexData) x;
            Vector#(4, ComplexData) twid;
            for (FftIdx j = 0; j < 4; j = j + 1 ) begin
                x[j] = stage_in[idx+j];
                twid[j] = getTwiddle(stage, idx+j);
            end
            let y = bfly[stage][i].bfly4(twid, x);

            for(FftIdx j = 0; j < 4; j = j + 1 ) begin
                stage_temp[idx+j] = y[j];
            end
        end

        stage_out = permute(stage_temp);

        return stage_out;
    endfunction

    rule sync_pipeline;
        if (inFifo.notEmpty) begin
            sReg1 <= tagged Valid(stage_f(0, inFifo.first));
            inFifo.deq;
        end
        else begin
            sReg1 <= tagged Invalid;
        end
    
        sReg2 <= (isValid(sReg1) ? tagged Valid(stage_f(1, fromMaybe(?, sReg1))) : tagged Invalid);

        if (isValid (sReg2))
            outFifo.enq(stage_f(2, fromMaybe(?, sReg2)));

    endrule

    method Action enq(Vector#(FftPoints, ComplexData) in);
        inFifo.enq(in);
    endmethod

    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
        outFifo.deq;
        return outFifo.first;
    endmethod
endmodule

// Exercise 3
(* synthesize *)
module mkFftElasticPipeline(Fft);
    // FIFOF#(Vector#(FftPoints, ComplexData)) inFifo <- mkFIFOF;
    // FIFOF#(Vector#(FftPoints, ComplexData)) outFifo <- mkFIFOF;
    // Vector#(NumStages, Vector#(BflysPerStage, Bfly4)) bfly1 <- replicateM(replicateM(mkBfly4));
    // Vector#(NumStages, Vector#(BflysPerStage, Bfly4)) bfly2 <- replicateM(replicateM(mkBfly4));
    // Vector#(NumStages, Vector#(BflysPerStage, Bfly4)) bfly3 <- replicateM(replicateM(mkBfly4));


endmodule

