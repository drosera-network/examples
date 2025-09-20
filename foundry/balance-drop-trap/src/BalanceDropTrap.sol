// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

// Bu tuzak, belirli bir cüzdanın ETH bakiyesindeki ani düşüşleri tespit eder.
contract BalanceDropTrap is ITrap {
    // İzlenecek cüzdanın adresi (Örnek olarak Vitalik Buterin'in adresi kullanılmıştır)
    address constant TARGET_WALLET = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B;
    // Alarm için eşik yüzdesi (Örn: %50'den fazla düşerse)
    uint256 constant THRESHOLD_PERCENT = 50;

    // Bu fonksiyon her blokta çalışır ve cüzdanın o anki ETH bakiyesini kaydeder.
    function collect() external view returns (bytes memory) {
        return abi.encode(TARGET_WALLET.balance);
    }

    // Bu fonksiyon, geçmiş bloklardaki verileri analiz eder.
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
        // Analiz için en az 2 blok verisi (önceki ve şimdiki bakiye) gerekir.
        if (data.length < 2) {
            return (false, bytes(""));
        }

        uint256 previousBalance = abi.decode(data[data.length - 2], (uint256));
        uint256 currentBalance = abi.decode(data[data.length - 1], (uint256));

        // Bakiye düşmediyse veya önceki bakiye 0 ise, sorun yoktur.
        if (currentBalance >= previousBalance || previousBalance == 0) {
            return (false, bytes(""));
        }

        // Düşüş miktarını ve yüzdesini hesapla.
        uint256 dropAmount = previousBalance - currentBalance;
        uint256 dropPercentage = (dropAmount * 100) / previousBalance;

        // Eğer düşüş yüzdesi belirlediğimiz eşikten büyükse, ALARM VER!
        if (dropPercentage >= THRESHOLD_PERCENT) {
            return (true, abi.encode(previousBalance, currentBalance));
        }

        // Eşikten küçükse, sorun yoktur.
        return (false, bytes(""));
    }
}
