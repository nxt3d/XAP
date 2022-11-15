//SPDX-License-Identifier: none

pragma solidity ^0.8.17;

interface IXAPRegistry{

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes10 indexed name, address owner);

    // Logged when a address is added or updated for a name.
    event NewAddress(bytes10 indexed name, uint chainId);

    function registerWithOwner(bytes10 name, uint chainId, address _address) external; 
        
    function setNameOwner(bytes10 name, address _address) external; 
    
    function register(bytes10 name, uint chainId, address _address) external; 

    function resolve(bytes10 name, uint chainId) external view returns (address);

    function nameOwner(bytes10 name) external view returns (address);

    function available(bytes10 name) external view returns (bool);

}