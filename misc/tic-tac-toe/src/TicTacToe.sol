// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {ITicTacToe} from "./interfaces/ITicTacToe.sol";

contract TicTacToe is ITicTacToe {
    Game internal game;
    address public drosera;


    modifier onlyDrosera() {
        require(msg.sender == drosera, "Only Drosera can call this function");
        _;
    }
    modifier inState(GameState _state) {
        require(game.state == _state, "Invalid game state");
        _;
    }

    constructor(address _droseraService) {
        drosera = _droseraService;
        game.state = GameState.WaitingForPlayers;
    }

    function joinGame() external inState(GameState.WaitingForPlayers) {
        if (game.playerX.playerAddress == address(0)) {
            game.playerX = Player({playerAddress: msg.sender, symbol: BoardSymbol.X});
        } else {
            require(game.playerO.playerAddress == address(0), "Game is full");
            game.playerO = Player({playerAddress: msg.sender, symbol: BoardSymbol.O});
            game.state = GameState.Playing;
            game.currentPlayer = game.playerX;
            emit GameStarted(game.playerX.playerAddress, game.playerO.playerAddress);
        }
    }

    function makeMove(uint8 _xCoord, uint8 _yCoord) external inState(GameState.Playing) {
        require(msg.sender == game.currentPlayer.playerAddress, "Not current player");
        // make a pending state to allow drosera to validate the move and check for win/draw
        game.pendingMove = PendingMove(_xCoord, _yCoord, game.currentPlayer);
    }

    // Drosera will call this function to finalize the move after validating and checking for win/draw
    function finalizeMove(uint8 _xCoord, uint8 _yCoord, Player memory _player, GameState _state) external onlyDrosera {
        game.board[_xCoord][_yCoord] = _player.symbol;
        emit MoveMade(_player.playerAddress, _xCoord, _yCoord, _player.symbol);
        if (_state == GameState.Won) {
            game.state = GameState.Won;
            emit GameWon(_player.playerAddress);
        } else if (_state == GameState.Draw) {
            game.state = GameState.Draw;
            emit GameDraw();
        } else {
            game.currentPlayer = game.currentPlayer.playerAddress == game.playerX.playerAddress ? game.playerO : game.playerX;
        }
    }

    function validateMove(uint8 _xCoord, uint8 _yCoord) external view returns (bool) {
        return game.board[_xCoord][_yCoord] == BoardSymbol.None;
    }

    function checkWin(BoardSymbol _player, Game memory _game) external pure returns (bool) {
    require(_player == BoardSymbol.X || _player == BoardSymbol.O, "Invalid player symbol");

    for (uint8 i = 0; i < 3; i++) {
        if (
            (_game.board[i][0] == _player && _game.board[i][1] == _player && _game.board[i][2] == _player) ||
            (_game.board[0][i] == _player && _game.board[1][i] == _player && _game.board[2][i] == _player)
        ) {
            return true;
        }
    }
    if (
        (_game.board[0][0] == _player && _game.board[1][1] == _player && _game.board[2][2] == _player) ||
        (_game.board[0][2] == _player && _game.board[1][1] == _player && _game.board[2][0] == _player)
    ) {
        return true;
    }
    return false;
}

    function checkDraw(Game memory _game) external pure returns (bool) {
        for (uint8 i = 0; i < 3; i++) {
            for (uint8 j = 0; j < 3; j++) {
                if (_game.board[i][j] == BoardSymbol.None) {
                    return false;
                }
            }
        }
        return true;
    }

    function getGame() external view returns (Game memory) {
        return game;
    }
}