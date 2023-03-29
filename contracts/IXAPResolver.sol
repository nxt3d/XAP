//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IXAPRegistry} from "./IXAPRegistry.sol";
import {IMutableRegistry} from "./IMutableRegistry.sol";

interface IXAPResolver {

    function xap() external view returns (IXAPRegistry);

    function mutableRegistry() external view returns (IMutableRegistry);

    function parentName() external view returns (bytes memory);

    function setParentName(bytes memory name) external;

    function resolve(bytes memory name, bytes memory data)
        external
        view
        returns (bytes memory, address);

}