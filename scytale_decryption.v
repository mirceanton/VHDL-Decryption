`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:     A.C.S
// Engineer:    Anton Mircea-Pavel
// 
// Create Date:     19:24:12 11/27/2020 
// Design Name: 
// Module Name:     scytale_decryption 
// Project Name:    Tema2_Decryption
// Target Devices:  N/A
// Tool versions:   14.5
// Description:     This block decrypts an scytale-encrypted message and
//                  sends it out, one character at a time
//
// Dependencies: N/A
//
// Revision: 
// Revision 0.01 - File Created
// Revision 0.02 - Doc Comments Added
// Revision 0.03 - First attempt at an implementation
// Revision 0.04 - Comment out $display and $write commands
// Revision 0.05 - General Logic Exmplained in top comment
// Revision 0.06 - Remove dumb comment & Change BA to NBA in always block
// Revision 0.07 - Merge nested ifs into a single one with cond1 & cond2
// Revision 0.08 - Change all tabs to spaces since Xilinx uses a 3-spaces-wide
//                 tab (WTF??) and all the code looks messy as a result of that.
// Revision 0.09 - Make a single reset state, instead of having 2
// Revision 0.10 - Add more comments along the way to explain what we're doing
//////////////////////////////////////////////////////////////////////////////////
module scytale_decryption#(
            parameter D_WIDTH = 8, 
            parameter KEY_WIDTH = 8, 
            parameter MAX_NOF_CHARS = 50,
            parameter START_DECRYPTION_TOKEN = 8'hFA
        )(
            // Clock and reset interface
            input clk,      // system clock
            input rst_n,    // negated reset
            
            // Input interface
            input[D_WIDTH - 1:0] data_i,    // The encrypted message
            input valid_i,                  // Input enable
            
            // Decryption Keys
            input[KEY_WIDTH - 1 : 0] key_N,     // Matrix columns
            input[KEY_WIDTH - 1 : 0] key_M,     // Matrix rows
            
            // Output interface
            output reg busy,                    // Indicates processing is taking place
            output reg[D_WIDTH - 1:0] data_o,   // The decrypted message
            output reg valid_o                  // Output enable
    );
    /////////////////////////// LOGIC OVERVIEW ///////////////////////////
    //    Everything happens on the positive edge of the [clk] signal   //
    //                                                                  //
    //    We're basically implementing a nested for loop                //
    //    The loop is then broken down as to execute one iteration per  //
    //    clock cycle.                                                  //
    //    The implemented loop is:                                      //
    //    for (int j = 0; j < key_N; j++) {                             //
    //        for (int k = j; k < i; k += key_N) {                      //
    //            print( message[k] );                                  //
    //        }                                                         //
    //    }                                                             //
    //                                                                  //
    //    As such, 2 aux variables are needed, j and k, to keep track of//
    //    the current position in the vector.                           //
    //////////////////////////////////////////////////////////////////////

    reg [D_WIDTH * MAX_NOF_CHARS - 1 : 0] message = 0;  // the encrypted message
    reg [KEY_WIDTH - 1 : 0] n = 0;  // the length of the encrypted message

    // Some auxiliary indexes i had no better names for
    reg [KEY_WIDTH - 1 : 0] i = 0;
    reg [KEY_WIDTH - 1 : 0] j = 0;

    always @(posedge clk) begin
        if (rst_n && valid_i) begin // reading the encrypted message
            // if we have not yet reached the end of the message, store each
            // letter into [message]
            // Note that message will have the string stored backwards
            if (data_i != START_DECRYPTION_TOKEN && !busy) begin
                message[D_WIDTH * n +: D_WIDTH ] <= data_i;
                n <= n + 1; // increment the character counter
            end else begin
                // Set indexes to 0
                i <= 0; j <= 0;
                busy <= 1;  // let the other devices connected to us know
                            // that we are busy
            end
        end

        if (busy) begin // output-ing the decrypted message
            // This prints the i'th line of the matrix
            if (j < n) begin
                valid_o <= 1;   // Set output_enable to high, so that
                                // other devices connected to us know
                                // we're not spitting bullshit rn
                data_o <= message[D_WIDTH * j +: D_WIDTH ];
                j <= j + key_N;
            end else begin
                valid_o <= 1;   // Same as above
                i <= i + 1; // Go to the next line
                
                // j becomes i+1 and not i because in the nested loop, blocking
                // assignments are implemented, and i++; j=i; means that j = i+1;
                // We have to also add key_N to j because we have to output some
                // data this iteration to. So we're basically performing
                // both an iteration and an incrementation in the same cycle
                // So this is basically the j needed for the second iteration
                // in the next loop
                j <= i + 1 + key_N;
                
                // the first iteration being implemented here
                if (i + 1 < key_N) begin
                    data_o <= message[D_WIDTH * (i+1) +: D_WIDTH ];
                end
            end
        end

        // If we were to model a FSM, this is the reset state
        // The events that would send us into such a state are:
        // 1. if the reset signal is high (rst_n is LOW)
        // 2. If we were hard working boys (or girls) and we just
        //    finished decrypting a message and outputting it
        // In both of those cases, we would like to reset all values
        // as to not interfere with future decryptions.
        //Ltp·tpehabhatesees··t··t//(4)
        if ( rst_n == 0 || (i+1 >= key_N && j >= n)) begin
            n <= 0; i <= 0; j <= 0;
            message <= 0;
            valid_o <= 0;
            data_o <= 0;
            busy <= 0;
        end
    end
endmodule
