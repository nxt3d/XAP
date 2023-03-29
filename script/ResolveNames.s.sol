// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {USDOracleMock} from "../contracts/mocks/USDOracleMock.sol";
import {IXAPRegistry} from "../contracts/IXAPRegistry.sol";
import {IXAPResolver} from "../contracts/IXAPResolver.sol";
import {IXAPRegistrar} from "../contracts/IXAPRegistrar.sol";
import {IAggregatorInterface} from "../contracts/IAggregatorInterface.sol";

contract ResolveNames is Script {

    //---------------------------- Goerli ------------------------------ //
    //address account = address(0x9bDBB7a40d346b86953E311E32F7573F8989BaB3);

    //---------------------------- Anvil ------------------------------ //
    // Anvil first account for local testing

    address account = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    //----------------------------------------------------------------- //
    function run() external {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        //---------------------------- Goerli ------------------------------ //

        //IXAPResolver resolver = IXAPResolver(address(0x3edA9579DC9f7563643187Eb9D71add6df4b7002));

        //---------------------------- Anvil ------------------------------ //

        IXAPResolver resolver = IXAPResolver(address(0x520497595f742426708dfbDcaB9D0D7D8555D937));

        //----------------------------------------------------------------- //

        vm.startBroadcast(deployerPrivateKey);

        // Resolve the address of the name
        console.log("resolve: xap22.eth:"); // (0x0578617032320365746800) 
        (bytes memory result, ) = resolver.resolve(bytes("\x05xap22\x03eth\x00"), 
            abi.encodeWithSelector(bytes4(0xf1cb7e06), bytes32(0), uint256(60)));
        console.log("result:");
        console.logBytes(result);

        // Resolve the address of the name
        console.log("resolve: addr-123.xap22.eth with CoinType 60 (chainId 1):");
        (bytes memory result1, ) = resolver.resolve(bytes("\x08addr-123\x05xap22\x03eth\x00"), 
            abi.encodeWithSelector(bytes4(0xf1cb7e06), bytes32(0), uint256(60)));
        console.log("result:");
        console.logBytes(result1);

        // Resolve the address of the name
        console.log("resolve: arb1-123.xap22.eth with CoinType 2147525809 (chainId 42161):");
        console.log("uint256(0x80000000) | uint256(42161):", uint256(0x80000000) | uint256(42161));
        (bytes memory result2, ) = resolver.resolve(bytes("\x08arb1-123\x05xap22\x03eth\x00"), 
            abi.encodeWithSelector(bytes4(0xf1cb7e06), bytes32(0), uint256(0x80000000) | uint256(42161)));
        console.log("result2:");
        console.logBytes(result2);

        // Resolve the text record of the name
        console.log("resolve text record: addr-123.xap22.eth with CoinType 60: (chainId 1)");
        (bytes memory txt1, ) = resolver.resolve(bytes("\x08addr-123\x05xap22\x03eth\x00"), 
            abi.encodeWithSelector(bytes4(0x59d1d43c), bytes32(0), "xap-address-data-1"));
        console.log("text record:");
        console.log(string(txt1));

        // Resolve the text record of the name
        console.log("resolve text record: arb1-123.xap22.eth with CoinType 2147525809 (chainId 42161):");
        (bytes memory txt2, ) = resolver.resolve(bytes("\x08arb1-123\x05xap22\x03eth\x00"), 
            abi.encodeWithSelector(bytes4(0x59d1d43c), bytes32(0), "xap-address-data-42161"));
        console.log("text record:");
        console.log(string(txt2));

        // Resolve the content record of the name
        console.log("resolve text record: addr-123.xap22.eth:");
        (bytes memory con1, ) = resolver.resolve(bytes("\x08addr-123\x05xap22\x03eth\x00"), 
            abi.encodeWithSelector(bytes4(0xbc1c58d1), bytes32(0)));
        console.log("content record:");
        console.log(string(con1));

        vm.stopBroadcast();
    }

}