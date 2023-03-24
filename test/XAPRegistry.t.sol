//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "contracts/XAPRegistry.sol";
import "contracts/IXAPRegistry.sol";
import "contracts/mocks/USDOracleMock.sol";

contract XAPRegistryTest is Test{

    address account = 0x0000000000000000000000000000000000003511;
    address account2 = 0x0000000000000000000000000000000000004612;

    XAPRegistry xap; 

    function setUp() public {

        // Set the block and timestamp.
        vm.roll(16560244);
        vm.warp(1675571853);

        // Set the active caller to 'account' and give 'account' 100 ETH.
        vm.startPrank(account);
        vm.deal(account, 100000000000000000000);

        // Deploy the oracle mock up.
        USDOracleMock usdOracle = new USDOracleMock();

        // Deploy the XAPRegistry.
        xap = new XAPRegistry();

        // Set up a XAP address.
        xap.setController(account, true);
        xap.register(bytes10(bytes("usd-oracle")), account, block.chainid, address(usdOracle)); 
        assertEq(xap.resolveAddress(bytes10(bytes("usd-oracle")), block.chainid), address(usdOracle));

    }
    // Create a Subheading using an empty function.
    function test1000_________________________________________________________________________() public {}
    function test2000______________________________XAP_REGISTRY_______________________________() public {}
    function test3000_________________________________________________________________________() public {}

    function test_001____register____________________RegisterAXAPAddress() public {

        // The current caller 'account' has been set as a controller so it can register a subname.
        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account2, block.chainid, account2); 
        assertEq(xap.resolveAddress(bytes10(bytes("addr-two")), block.chainid), account2);

    }

    // Test the supportsInterface function.
    function test_002____supportsInterface___________SupportsCorrectInterfaces() public {

        // Check for the ISubnameWrapper interface.  
        assertEq(xap.supportsInterface(type(IXAPRegistry).interfaceId), true);

        // Check for the IERC165 interface.  
        assertEq(xap.supportsInterface(type(IERC165).interfaceId), true);
    }

    // Test the registerWithData function.
    function test_003____registerWithData____________RegisterAXAPAddress() public {

        uint96 accountData = uint96(0x01);
        uint96 addressData = uint96(0x02);

        // The current caller 'account' has been set as a controller so it can register a subname.
        // Set up a XAP address.
        xap.registerWithData(bytes10(bytes("addr-two")), account2, accountData, block.chainid, account, addressData); 

        // Check to make sure that the address of chainId and auxiliary data is correct.
        (address resolvedAddress, uint96 resolvedAddressData) = 
            xap.resolveAddressWithData(bytes10(bytes("addr-two")),block.chainid);
        assertEq(resolvedAddress, account);
        assertEq(resolvedAddressData, addressData);

        // Check to make sure the owner and account data is correct.
        (address resolvedOwner, uint96 resolvedAccountData) = 
            xap.getOwnerWithData(bytes10(bytes("addr-two")));

        assertEq(resolvedOwner, account2);
        assertEq(resolvedAccountData, accountData);
    }

    // Test the registerAddress function.
    function test_004____registerAddress_____________RegisterAXAPAddress() public {

        // Set up a XAP account and second address.
        xap.register(bytes10(bytes("addr-two")), account, 77, account2); 
        xap.registerAddress(bytes10(bytes("addr-two")), 60, account); 
        assertEq(xap.resolveAddress(bytes10(bytes("addr-two")), 60), account);

        // Expect a revert with custom error message.
        vm.expectRevert( abi.encodeWithSelector(AccountImmutable.selector, bytes10(bytes("addr-two")), 60, account)); 
        xap.registerAddress(bytes10(bytes("addr-two")), 60, account2); 

    }

    // Test the registerAddressWithData function.
    function test_005____registerAddressWithData_____RegisterAXAPAddressWithAccountData() public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account, 77, account2);
        // Add an address to the XAP address.
        xap.registerAddressWithData(bytes10(bytes("addr-two")), 60, account2, uint96(2334556)); 
        (address resolvedAddress, uint96 resolvedData) = 
            xap.resolveAddressWithData(bytes10(bytes("addr-two")), 60);

        assertEq(resolvedAddress, account2);
        assertEq(resolvedData, uint96(2334556));

        // Expect a revert with custom error message.
        vm.expectRevert( abi.encodeWithSelector(AccountImmutable.selector, bytes10(bytes("addr-two")), 60, account2)); 
        xap.registerAddressWithData(bytes10(bytes("addr-two")), 60, account2, uint96(2334556)); 

    }
    
    // Test the setOwner function.
    function test_006____setOwner____________________OwnerIsSetCorrectly() public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account, 60, account2); 
        assertEq(xap.getOwner(bytes10(bytes("addr-two"))), account);

        // Set the owner of the subname.
        xap.setOwner(bytes10(bytes("addr-two")), account);

        // Check to make sure the owner is correct.
        assertEq(xap.getOwner(bytes10(bytes("addr-two"))), account);

    }

    // Test the setAccountData function.
    function test_007____setAccountData______________AccountDataIsSetCorrectly() public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account, 60, account2); 
        assertEq(xap.getOwner(bytes10(bytes("addr-two"))), account);

        // Set the owner of the subname.
        xap.setAccountData(bytes10(bytes("addr-two")), uint96(2334556));

        // Check to make sure the account data is correct.
        (, uint96 accountData) = xap.getOwnerWithData(bytes10(bytes("addr-two")));
        assertEq(accountData, uint96(2334556));

    }

    // Test the resolveAddress function.
    function test_009____resolveAddress______________AddressIsResolvedCorrectly() public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account2, 60, account2); 
        assertEq(xap.resolveAddress(bytes10(bytes("addr-two")), 60), account2);

    }

    // Test the resolveAddressWithData function.
    function test_010____resolveAddressWithData______AddressAndDataAreResolvedCorrectly() public {

        // Set up a XAP address.
        xap.registerWithData(bytes10(bytes("addr-two")), account2, uint96(1223445), 60, account2, uint96(2334556)); 
        assertEq(xap.resolveAddress(bytes10(bytes("addr-two")), 60), account2);

        // Check to make sure the address data is correct.
        (address resolvedAddress, uint96 resolvedData) = 
            xap.resolveAddressWithData(bytes10(bytes("addr-two")), 60);
        assertEq(resolvedAddress, account2);
        assertEq(resolvedData, uint96(2334556));

    }

    // Test the getOwner function.
    function test_011____getOwner____________________OwnerIsRetrievedCorrectly() public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account2, 60, account2); 
        assertEq(xap.getOwner(bytes10(bytes("addr-two"))), account2);

    }

    // Test the getOwnerWithData function.
    function test_012____getOwnerWithData____________OwnerAndDataAreRetrievedCorrectly() public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account, 60, account2); 
        assertEq(xap.getOwner(bytes10(bytes("addr-two"))), account);

        // Set the address data of the name.
        xap.setAccountData(bytes10(bytes("addr-two")), uint96(2334556));

        // Check to make sure the address data is correct.
        (address resolvedOwner, uint96 resolvedData) = 
            xap.getOwnerWithData(bytes10(bytes("addr-two")));
        assertEq(resolvedOwner, account);
        assertEq(resolvedData, uint96(2334556));

    }

    // Test the available function.
    function test_013____available___________________NameIsAvailable() public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account2, 60, account2); 
        assertEq(xap.available(bytes10(bytes("addr-two"))), false);

        // Check to make sure the name is available.
        assertEq(xap.available(bytes10(bytes("addr-three"))), true);

    }

}