// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EToken} from "./interfaces/ITokens.sol";

contract EulerTrap is ITrap {
    IERC20 DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    EToken eDAI = EToken(0xe025E3ca2bE02316033184551D4d3Aa22024D9DC);
    address eulerCore = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
    uint256 daiThreshold = 15_000_000 ether;
    uint256 reserveThreshold = 80_000_000 ether;

    struct Snapshot {
        uint256 daiPool; // raw DAI sitting in the Euler core
        uint256 eDaiSupply; // total eDAI, in underlying units
        uint256 eDaiReserves; // reserveBalanceUnderlying()
        uint256 daiThreshold;
        uint256 reserveThreshold;
    }

    constructor() {}

    function collect() external view returns (bytes memory) {
        Snapshot memory s = Snapshot({
            daiPool: DAI.balanceOf(eulerCore),
            eDaiSupply: eDAI.totalSupplyUnderlying(),
            eDaiReserves: eDAI.reserveBalanceUnderlying(),
            daiThreshold: daiThreshold,
            reserveThreshold: reserveThreshold
        });
        return abi.encode(s);
    }

    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
        if (data.length < 2) return (false, "");

        Snapshot memory cur = abi.decode(data[0], (Snapshot));
        Snapshot memory prev = abi.decode(data[1], (Snapshot));

        // how much DAI left the pool
        uint256 outflow = prev.daiPool > cur.daiPool ? prev.daiPool - cur.daiPool : 0;
        // how many eDAI were donated
        uint256 reserveSpike = cur.eDaiReserves > prev.eDaiReserves ? cur.eDaiReserves - prev.eDaiReserves : 0;

        if (outflow >= cur.daiThreshold || reserveSpike >= cur.reserveThreshold) {
            return (true, bytes(""));
        }
        return (false, "");
    }
}
