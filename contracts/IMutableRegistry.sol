//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IMutableRegistry{

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed name, address owner);

    // Logged when a address is added or updated for a name.
    event NewAddress(bytes32 indexed name, uint chainId);

    function setApprovalForAll(address operator) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function approve(bytes32 name, address delegate) external;

    function isApprovedFor(address owner, bytes32 name, address delegate) external view returns (bool);

    function register(bytes32 name, address _owner, uint256 chainId, address _address) external;

    function registerWithData(bytes32 name, address _owner, bytes memory contentHash, uint256 chainId, address _address) external;

    function registerAddress(bytes32 name, uint256 chainId, address _address) external;

    function setOwner(bytes32 name, address _address) external;

    function setContentHash(bytes32 name, bytes memory _contentHash) external;

    function setTextRecord(bytes32 name, string memory key, string memory value) external;

    function resolveAddress(bytes32 name, uint256 chainId) external view returns (address);

    function getOwner(bytes32 name) external view returns (address);

    function available(bytes32 name) external view returns (bool);

}