// idk why this SPDX is needed but remix-ai said it tbh

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// Implementation of Rock Paper Scissors as Smart Contract
// We need at least 2 Functions one for the commitment and one for the reveal

contract RPS{
    enum Move { Rock, Paper, Scissors}
    address public player1;
    address public player2;
    bytes32 public player1Commit;
    bytes32 public player2Commit;
    Move public player1Move;
    Move public player2Move;

    //function to generate commitment off chain
    function generateCommit(uint v, uint rand) public pure returns(bytes32){
        return keccak256(abi.encodePacked(v, rand));
    }

    function commitMove(bytes32 commit) external {
        if (msg.sender == player1) {
            require(player1Commit == 0, "Player 1 has commited");
            player1Commit = commit;
        } else {
            require(player2Commit == 0, "Player 2 has comited");
            player2Commit = commit;
        }
    }

    function revealMove(uint move, uint rand) external {
        require(msg.sender == player1 || msg.sender == player2, "not a player");

        // recompute commitment and look if it matches the stored commitment
        bytes32 commit = generateCommit(move, rand);
        if (msg.sender == player1){
            require(commit == player1Commit, "Invalid commit for player1");
            player1Move = Move(move);
        } else {
            require(commit == player2Commit, "Invalid commit for player1");
            player2Move = Move(move);
        }

        determineWinner();
    }

    function determineWinner() internal view {
        if ((player1Move == Move.Rock && player2Move == Move.Scissors) ||
            (player1Move == Move.Scissors && player2Move == Move.Paper) ||
            (player1Move == Move.Paper && player2Move == Move.Rock)) {
            // Player 1 wins
        } else {
            // Player 2 wins
        }
    }


}