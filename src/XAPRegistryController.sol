//SPDX-License-Identifier: none 

pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Normalize} from "./Normalize.sol";
import {IXAPRegistry} from "./IXAPRegistry.sol";

contract XAPRegistryController is Ownable{

    IXAPRegistry xap;
    using Normalize for bytes10;

    constructor(IXAPRegistry _xap){

        xap = _xap;

        bytes10 name = 0x6E787433640000000000;
        name.checkNormalized();
        xap.registerWithOwner(0x6E787433640000000000, 1, msg.sender);

    }
    


}