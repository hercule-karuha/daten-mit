import CacheTypes::*;
import Vector::*;
import FShow::*;
import MemTypes::*;
import Types::*;
import ProcTypes::*;
import Fifo::*;
import Ehr::*;
import RefTypes::*;
import StQ::*;


typedef enum{Ready, StartMiss, SendFillReq, WaitFillResp, Resp} CacheStatus
    deriving(Eq, Bits);
module mkDCacheLHUSM#(CoreID id)(
        MessageGet fromMem,
        MessagePut toMem,
        RefDMem refDMem,
        DCache ifc
	);
endmodule
