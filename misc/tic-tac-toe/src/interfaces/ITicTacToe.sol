// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITicTacToe {
    struct Game {
        Player playerX;
        Player playerO;
        BoardSymbol[3][3] board;
        Player currentPlayer;
        GameState state;
        PendingMove pendingMove;
    }

    struct Player {
        BoardSymbol symbol;
        address playerAddress;
    }

    struct PendingMove {
        uint8 x;
        uint8 y;
        Player player;
    }

    enum BoardSymbol {
        None,
        X,
        O
    }
    enum GameState {
        WaitingForPlayers,
        Playing,
        Won,
        Draw
    }

    event GameStarted(address playerX, address playerO);
    event MoveMade(address player, uint8 x, uint8 y, BoardSymbol symbol);
    event GameWon(address winner);
    event GameDraw();

    function joinGame() external;
    function makeMove(uint8 _xCoord, uint8 _yCoord) external;
    function getGame() external view returns (Game memory);
    function finalizeMove(uint8 _xCoord, uint8 _yCoord, Player memory _player, GameState _state) external;
    function validateMove(uint8 _xCoord, uint8 _yCoord) external view returns (bool);
    function checkWin(BoardSymbol _player, Game memory _game) external view returns (bool);
    function checkDraw(Game memory _game) external view returns (bool);
}