// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {USDOracleMock} from "../contracts/mocks/USDOracleMock.sol";
import {XAPRegistry} from "../contracts/XAPRegistry.sol";
import {XAPResolver} from "../contracts/XAPResolver.sol";
import {XAPRegistrar} from "../contracts/XAPRegistrar.sol";
import {MutableRegistry} from "../contracts/MutableRegistry.sol";
import {IAggregatorInterface} from "../contracts/IAggregatorInterface.sol";

contract DeployXAP01 is Script {

    // ---------------- Depoy to Goerli ----------------//
    // forge script script/DeployXAP_1.s.sol --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv

    // Goerli account
    //address account = address(0x9bDBB7a40d346b86953E311E32F7573F8989BaB3);

    // Chainlink oracle for goerli.
    //IAggregatorInterface goerli_ETH_USD_Oracle = IAggregatorInterface(address(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e));

    // ---------------- Depoy to Anvil ----------------//
    // forge script script/DeployXAP_1.s.sol --fork-url http://localhost:8545 --private-key $PRIVATE_KEY --broadcast -vvvv 

    // Anvil first acocunt for local testing
    address account = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    //-------------------------------------------------//
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // ---------------- Depoy to Anvil ----------------//

        // This is used for local test string. 
        IAggregatorInterface goerli_ETH_USD_Oracle = IAggregatorInterface(address(new USDOracleMock()));

        //-------------------------------------------------//


        XAPRegistry xap = new XAPRegistry();
        XAPRegistrar registrar = new XAPRegistrar(xap, goerli_ETH_USD_Oracle);
        MutableRegistry mutableRegistry = new MutableRegistry();
        XAPResolver resolver = new XAPResolver(xap, mutableRegistry, bytes("\x05xap22\x03eth\x00"));

        // Set the pricing for the subname registrar. 
        uint256[] memory charAmounts = new uint256[](10);
        charAmounts[0] = 0; // (≈$5/year) calculated as $/sec with 18 decimals.
        charAmounts[1] = 0;
        charAmounts[2] = 0;
        charAmounts[3] = 0;
        charAmounts[4] = 0;
        charAmounts[5] = 0;
        charAmounts[6] = 0;
        charAmounts[7] = 5000000000000000000;
        charAmounts[8] = 5000000000000000000;
        charAmounts[9] = 5000000000000000000;

        registrar.setPricingForAllLengths(
            charAmounts
        );

        // Set the our account to be the controller.    
        mutableRegistry.setController(account, true);

        // register xap.eth in the mutable registry so that the registrar can return records
        // for the parent name xap.eth. 
        mutableRegistry.register(bytes("\x05xap22\x03eth\x00"), account, 1, account);

        address resolvedXAPAddress = mutableRegistry.resolveAddress(bytes("\x05xap22\x03eth\x00"), 1);
        console.log("Resolved XAP address using the Mutable Registry: ", resolvedXAPAddress);
        
        (bytes memory resolvedAddr,) = resolver.resolve(bytes("\x05xap22\x03eth\x00"), 
            abi.encodeWithSelector(bytes4(0xf1cb7e06), bytes32(0), uint256(60)));

        console.log("Resolved XAP address using the Resolver: ");
        console.logBytes(resolvedAddr);

        // Make the xap registrar the controller.
        xap.setController(address(registrar), true);

        // Make a commitment to register a name.    
        bytes32 commitment = registrar.makeCommitment(bytes32(bytes("addr-123")), account, bytes32(bytes5(0x1234567890))); 

        // Save the commitment.
        registrar.commit(commitment);

        // log the commitment.
        console.log("Commitment: ");
        console.logBytes32(commitment);

        // Make a commitment to register a name.    
        bytes32 commitment2 = registrar.makeCommitment(bytes32(bytes("arb1-123")), account, bytes32(bytes5(0x1234567890))); 

        // Save the commitment.
        registrar.commit(commitment2);

        // log the commitment.
        console.log("Commitment2: ");
        console.logBytes32(commitment2);

        // log the xap address.
        console.log("XAP address: ", address(xap));

        // log the mutable registry address.
        console.log("Mutable registry address: ", address(mutableRegistry));

        // log the registrar address.
        console.log("Registrar address: ", address(registrar));

        // log the resolver address.
        console.log("Resolver address: ", address(resolver));
    
        vm.stopBroadcast();

    }
}