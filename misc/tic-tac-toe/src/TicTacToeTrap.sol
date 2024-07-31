// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";
import {ITicTacToe} from "./interfaces/ITicTacToe.sol";

contract TicTacToeTrap is ITrap {
    ITicTacToe public ticTacToe;

    struct CollectOutput {
        ITicTacToe.GameState state;
        ITicTacToe.PendingMove pendingMove;
        ITicTacToe.Player currentPlayer;
        bool shouldRespond;
    }

    // NOTE: constructor args are used here only for testing purposes
    // - In production, the contract will be deployed with the deployed TicTacToe contract
    constructor(address _ticTacToe) {
        ticTacToe = ITicTacToe(_ticTacToe);
    }

    function collect() external view override returns (bytes memory) {
        ITicTacToe.Game memory game = ticTacToe.getGame();
        ITicTacToe.GameState state = game.state;
        ITicTacToe.PendingMove memory pendingMove = game.pendingMove;

        // Check if the game is in the Playing state
        if (state != ITicTacToe.GameState.Playing) {
            return abi.encode(CollectOutput(state, pendingMove, game.currentPlayer, false));
        }
        // Check if the current player is the same as the player who made the pending move
        if (game.currentPlayer.playerAddress != game.pendingMove.player.playerAddress) {
            return abi.encode(CollectOutput(state, pendingMove, game.currentPlayer, false));
        }
        // Check if the pending move is valid
        if (!ticTacToe.validateMove(pendingMove.x, pendingMove.y)) {
            return abi.encode(CollectOutput(state, pendingMove, game.currentPlayer, false));
        }
        // Make the pending board
        game.board[pendingMove.x][pendingMove.y] = game.currentPlayer.symbol;

        // Check for a draw
        if (ticTacToe.checkDraw(game)) {
            return abi.encode(CollectOutput(ITicTacToe.GameState.Draw, pendingMove, game.currentPlayer, true));
        }

        // Check for a win
        if (ticTacToe.checkWin(game.currentPlayer.symbol, game)) {
            return abi.encode(CollectOutput(ITicTacToe.GameState.Won, pendingMove, game.currentPlayer, true));
        }

        return abi.encode(CollectOutput(state, pendingMove, game.currentPlayer, true));

        

    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        CollectOutput memory status = abi.decode(data[0], (CollectOutput));

        return (status.shouldRespond, abi.encode(status.pendingMove.x, status.pendingMove.y, status.currentPlayer, status.state));

    }
}