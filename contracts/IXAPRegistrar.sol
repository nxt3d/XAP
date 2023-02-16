//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.17;

import {IXAPRegistry} from "./IXAPRegistry.sol";
import {IAggregatorInterface} from "./IAggregatorInterface.sol";


interface IXAPRegistrar {

    function xap() external view returns (IXAPRegistry);
    function usdOracle() external view returns (IAggregatorInterface);
    function minNumbers() external view returns (uint32);
    function minLetters() external view returns (uint32);
    function minCharacters() external view returns (uint32);
    function minCommitmentAge() external view returns (uint256);
    function maxCommitmentAge() external view returns (uint256);
    function charAmounts(uint256) external view returns (uint256);
    function commitments(bytes32) external view returns (uint256); 

    function makeCommitment(
        bytes32 name,
        address owner,
        bytes32 secret
    ) external pure returns (bytes32);

    function commit(bytes32 commitment) external;

    function claim(
        bytes32 name, 
        uint chainId, 
        address _address,
        bytes32 secret
    ) external payable;

    function setMinimumCharacters(uint32 _minNumbers, uint32 _minLetters, uint32 _minCharacters) external;

    function setPricingForAllLengths(
        uint256[] calldata _charAmounts
    ) external;

    function updatePriceForCharLength(
        uint16 charLength,
        uint256 charAmount
    ) external;

    function addNextPriceForCharLength(
        uint256 charAmount
    ) external;

    function getLastCharIndex() external view returns (uint256);

    function setMinMaxCommitmentAge(uint256 _minCommitmentAge, uint256 _maxCommitmentAge) external;

    function getMinimums() external view returns(uint32,uint32,uint32);

    function getRandomName(
        uint256 maxLoops, 
        uint256 _minNumbers, 
        uint256 _minLetters, 
        uint256 _numChars,
        uint256 _salt
    ) external view returns (bytes32);
}