//SPDX-License-Identifier: none 

pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Normalize} from "./Normalize.sol";
import {IXAPRegistry} from "./IXAPRegistry.sol";

contract XAPRegistryController is Ownable{

    IXAPRegistry xap;
    using Normalize for bytes10;

    uint32 minLetters;
    uint32 minNumbers;
    uint32 minChars;

    constructor(IXAPRegistry _xap){

        xap = _xap;

        minNumbers = 3;
        minLetters = 3;
        minChars = 7;

    }

    function setMins(uint32 _minNumbers, uint32 _minLetters, uint32 _minChars) public onlyOwner{

       minNumbers = _minNumbers;
       minLetters = _minLetters;
       minChars = _minChars;

    }

    function getMins() public view returns(uint32,uint32,uint32){
        return (minNumbers, minLetters, minChars);
    }

    function claim(bytes10 name, uint chainId, address _address) external {

        name.checkNormalized(3, 3, 7);
        xap.registerWithOwner(name, chainId, _address);

    }   
    

}