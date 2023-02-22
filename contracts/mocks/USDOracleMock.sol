//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contracts/IAggregatorInterface.sol";

contract USDOracleMock is IAggregatorInterface{

    int256 public latestPrice = 163444000000;

    function latestAnswer() external view returns (int256){
        return int256(latestPrice);
    }

}

