// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {USDOracleMock} from "../contracts/mocks/USDOracleMock.sol";
import {IXAPRegistry} from "../contracts/IXAPRegistry.sol";
import {IXAPResolver} from "../contracts/IXAPResolver.sol";
import {IXAPRegistrar} from "../contracts/IXAPRegistrar.sol";
import {IAggregatorInterface} from "../contracts/IAggregatorInterface.sol";

contract DeployXAP2 is Script {

    //address account = address(0x9bDBB7a40d346b86953E311E32F7573F8989BaB3);
    //IAggregatorInterface goerli_ETH_USD_Oracle = IAggregatorInterface(address(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e));

    // Anvil first acocunt for local testing
    address payable account = payable(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));

    function run() external {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        //IXAPRegistry xap = IXAPRegistry(address(0x9bDBB7a40d346b86953E311E32F7573F8989BaB3));
        IXAPRegistrar registrar = IXAPRegistrar(address(0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9));
        //IXAPResolver resolver = IXAPResolver(address(0x9bDBB7a40d346b86953E311E32F7573F8989BaB3));

        vm.startBroadcast(deployerPrivateKey);

        //registrar.nothing();

        // Register the name, sending 1 ETH, which is more ether than needed. A refund will occur if successful.
        registrar.claim{value: 1000000000000000000}(bytes32(bytes("addr-123")), uint96(bytes12(bytes("this is text"))), 1, account, uint96(bytes12(0x6869686F77617265796F752E)), bytes32(bytes5(0x1234567890)));

        // Register a nam on the Arbitrum One chain, sending 1 ETH, which is more ether than needed. 
        registrar.claim{value: 1000000000000000000}(bytes32(bytes("arb1-123")), uint96(bytes12(bytes("this is text"))), 42161, account, uint96(bytes12(0x6869686F77617265796F7521)), bytes32(bytes5(0x1234567890)));

        vm.stopBroadcast();
    }

}