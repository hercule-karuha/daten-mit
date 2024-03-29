// Reference functions that use Bluespec's '*' operator
function Bit#(TAdd#(n,n)) multiply_unsigned( Bit#(n) a, Bit#(n) b );
    UInt#(n) a_uint = unpack(a);
    UInt#(n) b_uint = unpack(b);
    UInt#(TAdd#(n,n)) product_uint = zeroExtend(a_uint) * zeroExtend(b_uint);
    return pack( product_uint );
endfunction

function Bit#(TAdd#(n,n)) multiply_signed( Bit#(n) a, Bit#(n) b );
    Int#(n) a_int = unpack(a);
    Int#(n) b_int = unpack(b);
    Int#(TAdd#(n,n)) product_int = signExtend(a_int) * signExtend(b_int);
    return pack( product_int );
endfunction

// Exercise 2
// Multiplication by repeated addition
function Bit#(TAdd#(n,n)) multiply_by_adding( Bit#(n) a, Bit#(n) b );
    Bit#(n) temp = 0;
    Bit#(n) prod = 0;
    for(Integer i = 0; i < valueOf(n); i = i + 1) begin
        Bit#(TAdd#(n,1)) a_ex = (b[i]==0) ? 0 : zeroExtend(a);
        Bit#(TAdd#(n,1)) temp_ex = zeroExtend(temp);
        Bit#(TAdd#(n,1)) sum = temp_ex + a_ex;
        prod[i] = sum[0];
        temp = sum[valueOf(n):1]; 
    end
    return {temp,prod};
endfunction

// Multiplier Interface
interface Multiplier#( numeric type n );
    method Bool start_ready();
    method Action start( Bit#(n) a, Bit#(n) b );
    method Bool result_ready();
    method ActionValue#(Bit#(TAdd#(n,n))) result();
endinterface


// Exercise 4
// Folded multiplier by repeated addition
module mkFoldedMultiplier( Multiplier#(n) );
    Reg#(Bit#(n)) a <- mkRegU();
    Reg#(Bit#(n)) b <- mkRegU();
    Reg#(Bit#(n)) prod <-mkRegU();
    Reg#(Bit#(n)) tp <- mkReg(0);
    Reg#(Bit#(n)) i <- mkReg( fromInteger(valueOf(n)+1) );

    rule mulStep( i < fromInteger(valueOf(n)) );
        Bit#(TAdd#(n,1)) m = ( (b[i]==0)? 0 : zeroExtend(a) );
        Bit#(TAdd#(n,1)) tp_ex = zeroExtend(tp);
        Bit#(TAdd#(n,1)) sum = m + tp_ex;
        prod[i] <= sum[0];
		tp <= sum[valueOf(n) : 1];
        i <= i + 1;
    endrule

    method Bool start_ready();
        return i == fromInteger(valueOf(TAdd#(n,1)));
    endmethod
    
    method Action start(Bit#(n) aIn, Bit#(n) bIn) if (i == fromInteger(valueOf(TAdd#(n,1))));
        a <= aIn;
        b <= bIn;
        i <= fromInteger(0);
        tp <= fromInteger(0);
        prod <= fromInteger(0);
    endmethod

    method Bool result_ready();
        return i==fromInteger(valueOf(n));
    endmethod

    method ActionValue#(Bit#(TAdd#(n,n))) result() if (i == fromInteger(valueOf(n)));
        i <= i + 1;
        return {tp,prod};
    endmethod

endmodule



function Bit#(n) arth_shift(Bit#(n) a, Integer n, Bool right_shift);
    Int#(n) a_int = unpack(a);
    Bit#(n) out = 0;
    if (right_shift) begin
        out = pack(a_int >> n);
    end else begin //left shift
        out = pack(a_int <<n); end
    return out;
endfunction


// Exercise 6
// Booth Multiplier
module mkBoothMultiplier( Multiplier#(n) );
    Reg#(Bit#(TAdd#(TAdd#(n,n), 1))) m_pos <-mkRegU();
    Reg#(Bit#(TAdd#(TAdd#(n,n), 1))) m_neg <- mkRegU();
    Reg#(Bit#(TAdd#(TAdd#(n,n), 1))) p <- mkRegU();
    Reg#(Bit#(n)) i <- mkReg( fromInteger(valueOf(n)+1) );


    rule mulStep( i < fromInteger(valueOf(n)) );
        Bit#(2) pr = p[1:0];
        Bit#(TAdd#(TAdd#(n,n),1)) p_next = 0; 

        case(pr) matches
            2'b01: p_next = p + m_pos;
            2'b10: p_next = p + m_neg;
            default: p_next = p;
        endcase

        p <= arth_shift(p_next, 1, True);
        i <= i + 1;
    endrule
    
    method Bool start_ready();
        return i == fromInteger(valueOf(TAdd#(n,1)));
    endmethod

    method Action start(Bit#(n) m, Bit#(n) r) if (i == fromInteger(valueOf(TAdd#(n,1))));
        m_pos <= {m, 0};
        m_neg <= {-m, 0};
        p <= {0, r, 1'b0};
        i <= 0;
    endmethod

    method Bool result_ready();
        return i == fromInteger(valueOf(n));
    endmethod

    method ActionValue#(Bit#(TAdd#(n,n))) result() if (i == fromInteger(valueOf(n)));
        i <= i + 1;
        return p[valueOf(TAdd#(n,n)):1];
    endmethod
endmodule



// Exercise 8
// Radix-4 Booth Multiplier
module mkBoothMultiplierRadix4( Multiplier#(n) );
    Reg#(Bit#(TAdd#(TAdd#(n,n), 2))) m_pos <-mkRegU();
    Reg#(Bit#(TAdd#(TAdd#(n,n), 2))) m_neg <- mkRegU();
    Reg#(Bit#(TAdd#(TAdd#(n,n), 2))) p <- mkRegU();
    Reg#(Bit#(n)) i <- mkReg( fromInteger(valueOf(n) / 2 + 1) );

    rule mulStep( i < fromInteger(valueOf(n) / 2) );
        Bit#(3) pr = p[2:0];
        Bit#(TAdd#(TAdd#(n,n),2)) p_next = 0; 
        case(pr)
		    3'b001: p_next = p + m_pos;
		    3'b010: p_next = p + m_pos;
		    3'b011: p_next = p + (m_pos << 1);
		    3'b100: p_next = p + (m_neg << 1);
		    3'b101: p_next = p + m_neg;
		    3'b110: p_next = p + m_neg;
		    default: p_next = p;
		endcase
        p <= arth_shift(p_next, 2, True);
        i <= i + 1;
    endrule
    
    method Bool start_ready();
        return i == fromInteger(valueOf(n) / 2 + 1);
    endmethod

    method Action start(Bit#(n) m, Bit#(n) r) if (i == fromInteger(valueOf(n) / 2 + 1));
       m_pos <= {msb(m), m, 0};
       m_neg <= {msb(-m), (-m), 0};
       p <= {0, r, 1'b0};
       i <= 0;
    endmethod

    method Bool result_ready();
    return i == fromInteger(valueOf(n) / 2);
    endmethod

    method ActionValue#(Bit#(TAdd#(n,n))) result() if (i == fromInteger(valueOf(n) / 2));
        i <= i + 1;
        return p[valueOf(TAdd#(n,n)):1];
    endmethod
endmodule
