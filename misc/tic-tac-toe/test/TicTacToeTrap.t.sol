// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TicTacToeTrap} from "../src/TicTacToeTrap.sol";
import {TicTacToe} from "../src/TicTacToe.sol";
import {ITicTacToe} from "../src/interfaces/ITicTacToe.sol";

contract TicTacToeTrapTest is Test {
    TicTacToe ticTacToe;
    address drosera;
    address player1;
    address player2;
    

    function setUp() public {
        drosera = makeAddr("drosera");
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        ticTacToe = new TicTacToe(drosera);
        vm.prank(player1);
        ticTacToe.joinGame();
        vm.prank(player2);
        ticTacToe.joinGame();


    }

    function testGameMechanics() external {
        (bool isValid, uint8 x_coord, uint8 y_coord, TicTacToe.Player memory _playerInfo, ITicTacToe.GameState _state) = _makeMove(player1, 0, 0);

        assertTrue(isValid, "Game should be valid");
        assertTrue(_state == ITicTacToe.GameState.Playing, "Game should be in Playing state");
        vm.prank(drosera);
        ticTacToe.finalizeMove(x_coord, y_coord, _playerInfo, _state);
        assertTrue(ticTacToe.getGame().state == ITicTacToe.GameState.Playing, "Game should be in Playing state");


        (isValid, x_coord, y_coord, _playerInfo, _state) = _makeMove(player2, 1, 0);
        vm.prank(drosera);
        ticTacToe.finalizeMove(x_coord, y_coord, _playerInfo, _state);
        assertTrue(_state == ITicTacToe.GameState.Playing, "Game should be in Playing state");


        (isValid, x_coord, y_coord, _playerInfo, _state) = _makeMove(player1, 0, 1);
        vm.prank(drosera);
        ticTacToe.finalizeMove(x_coord, y_coord, _playerInfo, _state);
        assertTrue(_state == ITicTacToe.GameState.Playing, "Game should be in Playing state");


        (isValid, x_coord, y_coord, _playerInfo, _state) = _makeMove(player2, 1, 1);
        vm.prank(drosera);
        ticTacToe.finalizeMove(x_coord, y_coord, _playerInfo, _state);
        assertTrue(_state == ITicTacToe.GameState.Playing, "Game should be in Playing state");

        (isValid, x_coord, y_coord, _playerInfo, _state) = _makeMove(player1, 0, 2);
        vm.prank(drosera);
        ticTacToe.finalizeMove(x_coord, y_coord, _playerInfo, _state);
        assertTrue(_state == ITicTacToe.GameState.Won, "Game should be in Won state");

    }

    function _makeMove(address _player, uint8 _xCoord, uint8 _yCoord) internal returns (bool, uint8, uint8, TicTacToe.Player memory, ITicTacToe.GameState){
        vm.prank(_player);
        ticTacToe.makeMove(_xCoord, _yCoord);
        bytes memory data = new TicTacToeTrap(address(ticTacToe)).collect();
        bytes[] memory output = new bytes[](1);
        output[0] = data;

        (bool shouldRespond, bytes memory validData) = new TicTacToeTrap(address(ticTacToe)).shouldRespond(output);
        (uint8 x_coord, uint8 y_coord, TicTacToe.Player memory _playerInfo, ITicTacToe.GameState _state) = abi.decode(validData, (uint8, uint8, ITicTacToe.Player, ITicTacToe.GameState));
        return (shouldRespond, x_coord, y_coord, _playerInfo, _state);
    }


}
