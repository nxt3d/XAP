//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IMutableRegistry{

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes  indexed name, address owner);

    // Logged when a address is added or updated for a name.
    event NewAddress(bytes indexed name, uint chainId);

    function setApprovalForAll(address operator) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function approve(bytes memory name, address delegate) external;

    function isApprovedFor(address owner, bytes memory name, address delegate) external view returns (bool);

    function register(bytes memory name, address _owner, uint256 chainId, address _address) external;

    function registerWithData(bytes memory name, address _owner, bytes memory contentHash, uint256 chainId, address _address) external;

    function registerAddress(bytes memory name, uint256 chainId, address _address) external;

    function setOwner(bytes memory name, address _address) external;

    function setContentHash(bytes memory name, bytes memory _contentHash) external;

    function setTextRecord(bytes memory name, string memory key, string memory value) external;

    function resolveAddress(bytes memory name, uint256 chainId) external view returns (address);

    function getOwner(bytes memory name) external view returns (address);

    function getContentHash (bytes memory name) external view returns (bytes memory);

    function getTextRecord (bytes memory name, string memory key) external view returns (string memory);

    function available(bytes memory name) external view returns (bool);

}