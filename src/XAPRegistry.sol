// SPDX-License-Identifier:

pragma solidity ^0.8.17;

import {Controllable} from "./Controllable.sol";
import {Normalize} from "./Normalize.sol";
import {IXAPRegistry} from "./IXAPRegistry.sol";

error Unauthorized(bytes10 name);

contract XAPRegistry is IXAPRegistry, Controllable {

    using Normalize for bytes10;

    struct Record {

        mapping(uint=>address) addresses;
        address owner;

    }

    mapping(bytes10=>Record) records;

    function registerWithOwner(bytes10 name, uint chainId, address _address) external onlyController{

        name.checkNormalized();
        if (available(name)){
            records[name].owner = _address;
            records[name].addresses[chainId] = _address;
        }

    }
        
    function setNameOwner(bytes10 name, address _address) external onlyNameOwner(name){

        records[name].owner = _address;

    }
    
    function register(bytes10 name, uint chainId, address _address) external onlyNameOwner(name){

        name.checkNormalized();
        records[name].addresses[chainId] = _address;

    }

    function resolve(bytes10 name, uint chainId) external view returns (address){

        return records[name].addresses[chainId];

    }

    function nameOwner(bytes10 name) public view returns (address){

        return records[name].owner;

    }

    function available(bytes10 name) public view returns (bool){

        return records[name].owner != address(0);

    }

    modifier onlyNameOwner(bytes10 name){

        if (nameOwner(name) != msg.sender){
            revert Unauthorized(name);
        }
        _;

    }

}