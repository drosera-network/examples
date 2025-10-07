// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BalanceDropTrap} from "../../src/BalanceDropTrap.sol";

// Test kontratımız, Foundry'nin Test kontratından miras alır.
contract BalanceDropTrapTest is Test {
    BalanceDropTrap public trap;

    // Bu fonksiyon, her testten önce çalışır ve tuzağımızı kurar.
    function setUp() public {
        trap = new BalanceDropTrap();
    }

    // Bu test, bakiye %50'den fazla düştüğünde tuzağın alarm vermesi gerektiğini doğrular.
    function testShouldRespondOnSignificantDrop() public {
        // Geçmiş verileri simüle ediyoruz.
        bytes[] memory data = new bytes[](2);
        
        // Önceki bakiye: 100 ETH
        data[0] = abi.encode(100 ether);
        // Şimdiki bakiye: 40 ETH (yani %60'lık bir düşüş)
        data[1] = abi.encode(40 ether);

        // Tuzağımızın shouldRespond fonksiyonunu bu sahte verilerle çağırıyoruz.
        (bool should, ) = trap.shouldRespond(data);

        // Sonucun 'true' olmasını bekliyoruz ve bunu doğruluyoruz.
        assertTrue(should, "Trap should respond on a >50% balance drop");
    }

    // Bu test, bakiye %50'den az düştüğünde tuzağın alarm VERMEMESİ gerektiğini doğrular.
    function testShouldNotRespondOnInsignificantDrop() public {
        bytes[] memory data = new bytes[](2);
        
        // Önceki bakiye: 100 ETH
        data[0] = abi.encode(100 ether);
        // Şimdiki bakiye: 80 ETH (yani %20'lik bir düşüş)
        data[1] = abi.encode(80 ether);

        (bool should, ) = trap.shouldRespond(data);

        // Sonucun 'false' olmasını bekliyoruz ve bunu doğruluyoruz.
        assertFalse(should, "Trap should NOT respond on a <50% balance drop");
    }
}
