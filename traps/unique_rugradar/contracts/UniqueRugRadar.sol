// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UniqueRugRadar {
    address public targetToken;
    uint256 public thresholdPct;

    event Collected(address token, address owner, bool ownerFound, uint256 totalSupply);

    constructor(address _token, uint256 _thresholdPct) {
        require(_token != address(0), "token = zero");
        targetToken = _token;
        thresholdPct = _thresholdPct;
    }

    function _tryOwner(address token) internal view returns (address owner, bool found) {
        bytes4 sel = bytes4(keccak256("owner()"));
        (bool ok, bytes memory data) = token.staticcall(abi.encodeWithSelector(sel));
        if (ok && data.length >= 32) {
            owner = abi.decode(data, (address));
            found = true;
        } else {
            owner = address(0);
            found = false;
        }
    }

    function collect() external view returns (bytes memory) {
        (address owner, bool ownerFound) = _tryOwner(targetToken);

        uint256 ts;
        bool tsFound;
        (bool ok, bytes memory data) = targetToken.staticcall(abi.encodeWithSelector(bytes4(keccak256("totalSupply()"))));
        if (ok && data.length >= 32) {
            ts = abi.decode(data, (uint256));
            tsFound = true;
        } else {
            ts = 0;
            tsFound = false;
        }

        emit Collected(targetToken, owner, ownerFound, ts);
        return abi.encode(ownerFound, owner, tsFound, ts);
    }

    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
        if (data.length < 2) {
            return (false, abi.encode(uint256(0)));
        }

        (, , bool tsFoundNew, uint256 tsNew) = abi.decode(data[0], (bool, address, bool, uint256));
        (, , bool tsFoundPrev, uint256 tsPrev) = abi.decode(data[1], (bool, address, bool, uint256));

        if (!tsFoundNew || !tsFoundPrev) {
            return (false, abi.encode(uint256(0)));
        }

        if (tsPrev == 0) {
            return (false, abi.encode(uint256(0)));
        }

        if (tsNew >= tsPrev) {
            return (false, abi.encode(uint256(0)));
        }

        uint256 drop = ((tsPrev - tsNew) * 100) / tsPrev;

        if (drop >= 10) {
            return (true, abi.encode(drop));
        }

        return (false, abi.encode(drop));
    }

    function setTargetToken(address _token) external {
        targetToken = _token;
    }

    function setThreshold(uint256 _pct) external {
        thresholdPct = _pct;
    }
}
