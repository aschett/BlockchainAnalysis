// idk why this SPDX is needed but remix-ai said it tbh

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


// Implementation of Rock Paper Scissors as Smart Contract
// We need at least 2 Functions one for the commitment and one for the reveal

contract RPS{
    enum Move { Rock, Paper, Scissors, None}    //we need the None for the initial state also Rock is 0, Paper is 1, Scissors is 2 and None is 3
    address constant public player1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;   //just the first 2 for trying out in remix. i think you could also just write something like _player1 or so.
    address constant public player2 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    bytes32 public player1Commit;
    bytes32 public player2Commit;
    Move public player1Move = Move.None;    //initiate them both as none
    Move public player2Move = Move.None;
    uint public betAmount;
    uint constant REVEAL_TIME = 5 hours;    // time for each of the players allowd to reveal their move
    uint public revealDeadline;

    //apparently is used to avoid reentrancy attacks
    mapping(address=>uint) public balances;


    //function to generate commitment off chain. or at least it should be done off chain lmao
    function generateCommit(Move move, uint nonce) public pure returns(bytes32){
        return keccak256(abi.encodePacked(move, nonce));
    }


    function commitMove(bytes32 commit) public payable {
        require((msg.sender == player1 && player1Commit == 0) || (msg.sender == player2 && player2Commit == 0), "either invalid player or already commited");
        require(msg.value == 1 ether, "Need 1 ether to participate");
        if(msg.sender == player1){
            player1Commit = commit;
        } else {
            player2Commit = commit;
        }

        //After both players ommited their moves we set the deadline to 5 hours after block creation
        if (player1Commit != 0 &&  player2Commit != 0){
            revealDeadline = block.timestamp + REVEAL_TIME;
        }
    }

    function revealMove(Move move, uint nonce) public {
        require(block.timestamp <= revealDeadline, "Reveal time has ben overstepped");
        require(msg.sender == player1 || msg.sender == player2, "not a player");
        require(player2Commit != 0 && player1Commit != 0, "someone didnt commit a hash");
        require(move != Move.None, "have to choose between Rock, Paper and Scissor");

        if (msg.sender == player1){
            require(player1Commit == keccak256(abi.encodePacked(move, nonce)), "Invalid commit for player1");
            player1Move = move;
        } else {
            require(player2Commit == keccak256(abi.encodePacked(move, nonce)), "Invalid commit for player2");
            player2Move = move;
        }

        // if both players reveal their values you can determine the winner
        if (player1Move != Move.None && player2Move != Move.None){
            determineWinner();
        }
        
    }

    function determineWinner() public {
        require(player1Move != Move.None && player2Move != Move.None, "at least one player didnt choose");
        if (player1Move == player2Move){
            // draw transfer money back to players
            balances[player1] += 1 ether;
            balances[player2] += 1 ether;
        }
        else if ((player1Move == Move.Rock && player2Move == Move.Scissors) ||
            (player1Move == Move.Scissors && player2Move == Move.Paper) ||
            (player1Move == Move.Paper && player2Move == Move.Rock)) {
            // Player 1 wins
            balances[player1] += 2 ether;
        } else {
            balances[player2] += 2 ether;
            // Player 2 wins
        }

        resetGame();
    }

    function withdraw() public{
        uint amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // apparently this is also a thing people do
    function resetGame() internal {
        player1Commit = bytes32(0);
        player2Commit = bytes32(0);
        player1Move = Move.None;
        player2Move = Move.None;
        revealDeadline = 0;
    }

    //function to pay out the person that committed
    function refundDeposit() public {
        bool didNotCommit = block.timestamp >= revealDeadline && (player1Commit == 0 || player2Commit == 0);
        bool didNotRevealCommit = block.timestamp >= revealDeadline && (player2Move == Move.None || player1Move == Move.None);
        require(didNotCommit || didNotRevealCommit, "Someone did not participate in the game");

        if (block.timestamp >= revealDeadline) {
            if (player1Move == Move.None && player2Move != Move.None){
                //player1 didnt show commitment
                balances[player2] += 2 ether;
            } else if (player2Move == Move.None && player1Move != Move.None){
                //player2 didnt show commitment
                balances[player1] += 2 ether;
            } else {
                balances[player1] += 1 ether;
                balances[player1] += 1 ether;
            }
        }
    }
}