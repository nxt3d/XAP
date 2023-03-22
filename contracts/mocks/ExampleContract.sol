//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../IXAPRegistry.sol";

contract ExampleContract {

    IXAPRegistry public xap;

    // XAP names can be stored with any length of bytes e.g. Bytes10 for a 
    // maximum ten character name. The maximum number of bytes is 32.

    bytes10 public xapName;

    constructor(IXAPRegistry _xap) {
        xap = _xap;
    }

    function resolveXAPAddress() public view returns (address) {
        return xap.resolveAddress(bytes32(xapName),1);
    }

    function setXAPName(bytes10 _name) public {
        xapName = _name;
    }
}