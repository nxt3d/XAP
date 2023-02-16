//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface IXAPResolver {

function resolve(bytes memory name, bytes memory data) external;

}