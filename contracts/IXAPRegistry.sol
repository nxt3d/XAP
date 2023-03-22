//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IXAPRegistry{

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed name, address owner);

    // Logged when a address is added or updated for a name.
    event NewAddress(bytes32 indexed name, uint chainId);

    function setApprovalForAll(address operator) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function approve(bytes32 name, address delegate) external;

    function isApprovedFor(address owner, bytes32 name, address delegate) external view returns (bool);

    function register(bytes32 name, address _owner, uint256 chainId, address _address) external;

    function registerWithData(bytes32 name, address _owner, uint96 accountData, uint256 chainId, address _address, uint96 addressData) external;

    function registerAddress(bytes32 name, uint256 chainId, address _address) external;

    function registerAddressWithData(bytes32 name, uint256 chainId, address _address, uint96 addressData) external;

    function setOwner(bytes32 name, address _address) external;

    function setAccountData(bytes32 name, uint96 accountData) external;

    function resolveAddress(bytes32 name, uint256 chainId) external view returns (address);

    function resolveAddressWithData(bytes32 name, uint256 chainId) external view returns (address, uint96);

    function getOwner(bytes32 name) external view returns (address);

    function getOwnerWithData(bytes32 name) external view returns (address, uint96);

    function available(bytes32 name) external view returns (bool);

}