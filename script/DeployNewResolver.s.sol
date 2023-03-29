// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {USDOracleMock} from "../contracts/mocks/USDOracleMock.sol";
import {XAPRegistry} from "../contracts/XAPRegistry.sol";
import {XAPResolver} from "../contracts/XAPResolver.sol";
import {XAPRegistrar} from "../contracts/XAPRegistrar.sol";
import {MutableRegistry} from "../contracts/MutableRegistry.sol";
import {IAggregatorInterface} from "../contracts/IAggregatorInterface.sol";

contract DeployNewResolver is Script {

    // ---------------- Depoy to Goerli ----------------//
    // forge script script/DeployXAP_1.s.sol --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv

    // Goerli account
    address account = address(0x9bDBB7a40d346b86953E311E32F7573F8989BaB3);

    // ---------------- Depoy to Anvil ----------------//
    // forge script script/DeployXAP_1.s.sol --fork-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast -vvvv 

    // Anvil first acocunt for local testing
    //address account = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    //-------------------------------------------------//
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);


        //----------------- XAP Registry ------------------//
        // Change to either the Goerli or Anvil addresses.

        XAPRegistry xap = XAPRegistry(address(0x63d7De52fFc88462eA7DB175C46b3e2177c04Cd3));
        MutableRegistry mutableRegistry = MutableRegistry(address(0x7081F0C5751c4D19Ca8b9fE9532D4c18C5fdD0eD));

        //-------------------------------------------------//

        console.log("owner of the XAP Registry: ", xap.owner());
        console.log("owner of the Mutable Registry: ", mutableRegistry.owner());

        XAPResolver resolver = new XAPResolver(xap, mutableRegistry, bytes("\x05xap22\x03eth\x00"));

        address resolvedXAPAddress = mutableRegistry.resolveAddress(bytes("\x05xap22\x03eth\x00"), 1);
        console.log("Resolved XAP address using the Mutable Registry: ", resolvedXAPAddress);
        
        (bytes memory resolvedAddr,) = resolver.resolve(bytes("\x05xap22\x03eth\x00"), 
            abi.encodeWithSelector(bytes4(0xf1cb7e06), bytes32(0), uint256(60)));

        console.log("Resolved XAP address using the Resolver: ");
        console.logBytes(resolvedAddr);

        // log the resolver address.
        console.log("Resolver address: ", address(resolver));
    
        vm.stopBroadcast();

    }
}