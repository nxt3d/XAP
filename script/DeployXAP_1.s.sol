// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {USDOracleMock} from "../contracts/mocks/USDOracleMock.sol";
import {XAPRegistry} from "../contracts/XAPRegistry.sol";
import {XAPResolver} from "../contracts/XAPResolver.sol";
import {XAPRegistrar} from "../contracts/XAPRegistrar.sol";
import {IAggregatorInterface} from "../contracts/IAggregatorInterface.sol";

contract DeployXAP1 is Script {

    //address account = address(0x9bDBB7a40d346b86953E311E32F7573F8989BaB3);
    //IAggregatorInterface goerli_ETH_USD_Oracle = IAggregatorInterface(address(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e));

    // Anvil first acocunt for local testing
    address account = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // This is used for local teststing. 
        IAggregatorInterface goerli_ETH_USD_Oracle = IAggregatorInterface(address(new USDOracleMock()));
        
        XAPRegistry xap = new XAPRegistry();
        XAPRegistrar registrar = new XAPRegistrar(xap, goerli_ETH_USD_Oracle);
        XAPResolver resolver = new XAPResolver(xap);

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

        // log the registrar address.
        console.log("Registrar address: ", address(registrar));

        // log the resolver address.
        console.log("Resolver address: ", address(resolver));

        vm.stopBroadcast();

    }
}