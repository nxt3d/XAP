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

    function test_001____register____________________RegisterAXAPAddress(bytes32 name) public {

        // The current caller 'account' has been set as a controller so it can register a subname.
        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account2, block.chainid, account2); 
        assertEq(xap.resolveAddress(bytes10(bytes("addr-two")), block.chainid), account2);

        // Check the register function this time using fuzzing.
        xap.register(name, account2, block.chainid, account2);
        assertEq(xap.resolveAddress(name, block.chainid), account2);

    }

    function test_002____register____________________RegisteringANameWithAZeroAddressReverts() public {

        // Check to make sure the setting the owner to address 0 reverts.
        vm.expectRevert(ZeroAddressOwner.selector);
        xap.register(bytes10(bytes("addr-two")), address(0), block.chainid, account); 

        // Check to make sure the setting the address to address 0 reverts.
        vm.expectRevert(ZeroAddress.selector);
        xap.register(bytes10(bytes("addr-two")), account2, block.chainid, address(0)); 

        // Check to make sure the setting the owner and the address to address 0 reverts.
        vm.expectRevert(ZeroAddressOwner.selector);
        xap.register(bytes10(bytes("addr-two")), address(0), block.chainid, address(0)); 

    }

    // Test the supportsInterface function.
    function test_003____supportsInterface___________SupportsCorrectInterfaces() public {

        // Check for the ISubnameWrapper interface.  
        assertEq(xap.supportsInterface(type(IXAPRegistry).interfaceId), true);

        // Check for the IERC165 interface.  
        assertEq(xap.supportsInterface(type(IERC165).interfaceId), true);
    }

    // Test the registerWithData function with address 0.
    function test_004____registerWithData____________RegisteringANameWithAZeroAddressReverts() public {

        uint96 accountData = uint96(0x01);
        uint96 addressData = uint96(0x02);

        // Check to make sure the setting the owner to address 0 reverts.
        vm.expectRevert(ZeroAddressOwner.selector);
        xap.registerWithData(bytes10(bytes("addr-two")), address(0), accountData, block.chainid, account, addressData); 

        // Check to make sure the setting the address to address 0 reverts.
        vm.expectRevert(ZeroAddress.selector);
        xap.registerWithData(bytes10(bytes("addr-two")), account2, accountData, block.chainid, address(0), addressData); 

        // Check to make sure the setting the owner and the address to address 0 reverts.
        vm.expectRevert(ZeroAddressOwner.selector);
        xap.registerWithData(bytes10(bytes("addr-two")), address(0), accountData, block.chainid, address(0), addressData); 
    }

    // Test the registerWithData function.
    function test_005____registerWithData____________RegisterAXAPAddress() public {

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
    function test_006____registerAddress_____________RegisterAXAPAddress() public {

        // The current caller 'account' has been set as a controller so it can register a subname.
        // Set up a XAP address.
        xap.registerAddress(bytes10(bytes("addr-two")), 60, account2); 
        assertEq(xap.resolveAddress(bytes10(bytes("addr-two")), 60), account2);

        // Expect a revert with custom error message.
        vm.expectRevert( abi.encodeWithSelector(AccountImmutable.selector, bytes10(bytes("addr-two")), 60, account2)); 
        xap.registerAddress(bytes10(bytes("addr-two")), 60, account2); 

    }  
    
    // Test the registerAddress function.
    function test_007____registerAddress_____________ZeroAddressesCannotBeRegistered() public {

        // The current caller 'account' has been set as a controller so it can register a subname.
        // Set up a XAP address.
        vm.expectRevert(ZeroAddress.selector);
        xap.registerAddress(bytes10(bytes("addr-two")), 1, address(0)); 

    }

    // Test the registerAddressWithData function.
    function test_008____registerAddressWithData_____RegisterAXAPAddressWithAccountData() public {

        // Set up a XAP address.
        xap.registerAddressWithData(bytes10(bytes("addr-two")), 60, account2, uint96(2334556)); 
        (address resolvedAddress, uint96 resolvedData) = 
            xap.resolveAddressWithData(bytes10(bytes("addr-two")), 60);

        assertEq(resolvedAddress, account2);
        assertEq(resolvedData, uint96(2334556));

        // Expect a revert with custom error message.
        vm.expectRevert( abi.encodeWithSelector(AccountImmutable.selector, bytes10(bytes("addr-two")), 60, account2)); 
        xap.registerAddressWithData(bytes10(bytes("addr-two")), 60, account2, uint96(2334556)); 

    }
    
    // Test the registerAddressWithData function.
    function test_009____registerAddressWithData_____ZeroAddressesCannotBeRegistered() public {

        // Check to make sure the setting the owner to address 0 reverts.
        vm.expectRevert(ZeroAddress.selector);
        xap.registerAddressWithData(bytes10(bytes("addr-two")), block.chainid, address(0), uint96(2334556)); 
    }
    
    // Test the setOwner function.
    function test_010____setOwner____________________OwnerIsSetCorrectly() public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account2, 60, account2); 
        assertEq(xap.getOwner(bytes10(bytes("addr-two"))), account2);

        // Set the owner of the subname.
        xap.setOwner(bytes10(bytes("addr-two")), account);

        // Check to make sure the owner is correct.
        assertEq(xap.getOwner(bytes10(bytes("addr-two"))), account);

    }

    // Test the setOwner function.
    function test_011____setOwner____________________ZeroAddressesCannotBeSet() public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account2, 60, account2); 
        assertEq(xap.getOwner(bytes10(bytes("addr-two"))), account2);

        // Set the owner of the subname to address 0.
        vm.expectRevert(ZeroAddressOwner.selector);
        xap.setOwner(bytes10(bytes("addr-two")), address(0));

    }

    // Test the setAccountData function.
    function test_012____setAccountData______________AccountDataIsSetCorrectly() public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account2, 60, account2); 
        assertEq(xap.getOwner(bytes10(bytes("addr-two"))), account2);

        // Set the owner of the subname.
        xap.setAccountData(bytes10(bytes("addr-two")), uint96(2334556));

        // Check to make sure the account data is correct.
        (, uint96 accountData) = xap.getOwnerWithData(bytes10(bytes("addr-two")));
        assertEq(accountData, uint96(2334556));

    }

    // Test the resolveAddress function.
    function test_013____resolveAddress______________AddressIsResolvedCorrectly() public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account2, 60, account2); 
        assertEq(xap.resolveAddress(bytes10(bytes("addr-two")), 60), account2);

    }

    // Test the resolveAddressWithData function.
    function test_014____resolveAddressWithData______AddressAndDataAreResolvedCorrectly() public {

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
    function test_015____getOwner____________________OwnerIsRetrievedCorrectly(address owner) public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account2, 60, account2); 
        assertEq(xap.getOwner(bytes10(bytes("addr-two"))), account2);

        // This time with fuzzing
        xap.register(bytes10(bytes("addr-three")), owner, 1, owner);
        assertEq(xap.getOwner(bytes10(bytes("addr-three"))), owner);

    }    
    
    // Test the getOwnerWithData function.
    function test_016____getOwnerWithData____________OwnerAndDataAreRetrievedCorrectly(bytes32 name, uint96 data) public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account2, 60, account2); 
        assertEq(xap.getOwner(bytes10(bytes("addr-two"))), account2);

        // Set the account data of the name.
        xap.setAccountData(bytes10(bytes("addr-two")), uint96(2334556));

        // Check to make sure the account data is correct.
        (address resolvedOwner, uint96 resolvedData) = 
            xap.getOwnerWithData(bytes10(bytes("addr-two")));
        assertEq(resolvedOwner, account2);
        assertEq(resolvedData, uint96(2334556));

        // This time with fuzzing

        // Set up a XAP address.
        xap.register(name, account2, 1, account2); 
        assertEq(xap.getOwner(name), account2);

        // Set the account data of the name.
        xap.setAccountData(name, data);

        // Check to make sure the account data is correct.
        (address resolvedOwnerFuzz, uint96 resolvedDataFuzz) = 
            xap.getOwnerWithData(name);
        assertEq(resolvedOwnerFuzz, account2);
        assertEq(resolvedDataFuzz, data);

    }

    // Test the available function.
    function test_017____available___________________NameIsAvailable(bytes32 name) public {

        // Set up a XAP address.
        xap.register(bytes10(bytes("addr-two")), account2, 60, account2); 
        assertEq(xap.available(bytes10(bytes("addr-two"))), false);

        // Check to make sure the name is available.
        assertEq(xap.available(bytes10(bytes("addr-three"))), true);
        
        // Fuzz test a bunch of names, that should all be available.
        assertEq(xap.available(name), true);

    }

}