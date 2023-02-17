//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IXAPRegistry} from "./IXAPRegistry.sol";



interface IXAPResolver {

    function xap() external view returns (IXAPRegistry);

    function resolve(bytes memory name, bytes memory data)
        external
        view
        returns (bytes memory, address);

}