// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract TimeSeriesTrap {
    uint256[] public historicalData;
    
    function collect() external returns (uint256) {
        uint256 newData = block.timestamp % 1000; // Пример данных
        historicalData.push(newData);
        return newData;
    }
    
    function shouldRespond(uint256[] calldata data) external pure returns (bool, bytes memory) {
        if (data.length < 5) return (false, "");
        
        uint256 sum;
        for (uint i = data.length-5; i < data.length; i++) {
            sum += data[i];
        }
        uint256 average = sum / 5;
        
        if (data[data.length-1] > average * 2) {
            return (true, abi.encode("Anomaly detected", average));
        }
        return (false, "");
    }
}
