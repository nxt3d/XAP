//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "contracts/XAPRegistry.sol";
import "contracts/IXAPResolver.sol";
import "contracts/XAPResolver.sol";
import {MutableRegistry} from "contracts/MutableRegistry.sol";
import "contracts/mocks/USDOracleMock.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract XAPResolverTest is Test{

    address account = 0x0000000000000000000000000000000000003511;
    address account2 = 0x0000000000000000000000000000000000004612;

    XAPRegistry xap; 
    XAPResolver resolver;
    MutableRegistry mutableRegistry;

    function setUp() public {

        // Set the block and timestamp.
        vm.roll(16560244);
        vm.warp(1675571853);

        // Set the active caller to 'account' and give 'account' 100 ETH.
        vm.startPrank(account);
        vm.deal(account, 100000000000000000000);

        // Deploy the XAPRegistry.
        xap = new XAPRegistry();

        mutableRegistry = new MutableRegistry();

        mutableRegistry.setController(account, true);

        // Register xap.eth in the mutable registry so that the registrar can return records
        // for the parent name xap.eth. 
        mutableRegistry.register(bytes("\x03xap\x03eth\x00"), account, 1, account2);

        // Set up a text record for xap.eth
        mutableRegistry.setTextRecord(bytes("\x03xap\x03eth\x00"), "test-text-record", "test text record value");
        mutableRegistry.setContentHash(bytes("\x03xap\x03eth\x00"), bytes("test content hash value"));

        // Deploy the XAPResolver.
        resolver = new XAPResolver(xap, mutableRegistry, bytes("\x03xap\x03eth\x00"));

        // Set up a XAP address.
        xap.setController(account, true);
        xap.registerWithData(bytes32(bytes("xyz-driver")), account, 100, 1, account2, 200); 
        assertEq(xap.resolveAddress(bytes32(bytes("xyz-driver")), 1), account2);

    }
    // Create a Subheading using an empty function.
    function test1000_________________________________________________________________________() public {}
    function test2000______________________________XAP_RESOLVER_______________________________() public {}
    function test3000_________________________________________________________________________() public {}

    function test_001____resolve_addr________________ResolveAnRootAddressXAPETH() public {

        // Check that the resolver can resolve the address.
        (bytes memory resolvedAddress, ) = 
            resolver.resolve(bytes("\x03xap\x03eth\x00"), 
                abi.encodeWithSelector(bytes4(0xf1cb7e06), bytes32(0), uint256(60)));


        // Check that the address is correct.
        assertEq(address(uint160(uint256(bytes32(resolvedAddress)))), account2);

    }
    function test_002____resolve_addr________________ResolveAnRootAddressXAPETHwithNoChainId() public {

        // Check that the resolver can resolve the address.
        (bytes memory resolvedAddress, ) = 
            resolver.resolve(bytes("\x03xap\x03eth\x00"), 
                abi.encodeWithSelector(bytes4(0x3b3b57de), bytes32(0)));


        // Check that the address is correct.
        assertEq(address(uint160(uint256(bytes32(resolvedAddress)))), account2);


    }
    function test_003____resolve_addr________________ResolveAnXAPAdressAsENSSubname() public {

        // Check that the resolver can resolve the address.
        (bytes memory resolvedAddress, ) = 
            resolver.resolve(bytes("\x0axyz-driver\x03xap\x03eth\x00"), 
                abi.encodeWithSelector(bytes4(0xf1cb7e06), bytes32(0), uint256(60)));


        // Check that the address is correct.
        assertEq(address(uint160(uint256(bytes32(resolvedAddress)))), account2);


    }

    function test_004____resolve_addr________________ResolveAnXAPAddressWithChainId42161AsENSSubname() public {

        xap.registerWithData(bytes32(bytes("abc-driver")), account, 100, 42161, account2, 200); 
        assertEq(xap.resolveAddress(bytes32(bytes("abc-driver")), 42161), account2);

        // Check that the resolver can resolve the address.
        (bytes memory resolvedAddress, ) = 
            resolver.resolve(bytes("\x0aabc-driver\x03xap\x03eth\x00"), 
                abi.encodeWithSelector(bytes4(0xf1cb7e06), bytes32(0), uint256(0x80000000) | uint256(42161)));
        // Check that the address is correct.
        assertEq(address(uint160(uint256(bytes32(resolvedAddress)))), account2);


    }

    function test_005____resolve_text________________ResolveTheTextRecordOfTheRootXAPETH() public {

        // Check that the resolver can resolve the address.
        (bytes memory resolvedTextRecord, ) = 
            resolver.resolve(bytes("\x03xap\x03eth\x00"), 
                abi.encodeWithSelector(bytes4(0x59d1d43c), bytes32(0), "test-text-record"));

    
        // Check that the address is correct.
        assertTrue( equalStrings(string(resolvedTextRecord), "test text record value"));
    }

    function test_006____resolve_text________________ResolveTheAddressDataOfAXAPAdress() public {

        // Check that the resolver can resolve the address.
        (bytes memory resolvedAddressData, ) = 
            resolver.resolve(bytes("\x0axyz-driver\x03xap\x03eth\x00"), 
                abi.encodeWithSelector(bytes4(0x59d1d43c), bytes32(0), "xap-address-data-1"));

    
        // Check that the address is correct.
        assertEq(uint96(uint256(bytes32(resolvedAddressData))), 200);
    }

    function test_007____resolve_text________________ResolveTheAddressDataOfAXAPAdressChainId42161() public {

        xap.registerWithData(bytes32(bytes("abc-driver")), account, 100, 42161, account2, 200); 
        assertEq(xap.resolveAddress(bytes32(bytes("abc-driver")), 42161), account2);

        // Check that the resolver can resolve the address.
        (bytes memory resolvedAddressData, ) = 
            resolver.resolve(bytes("\x0aabc-driver\x03xap\x03eth\x00"), 
                abi.encodeWithSelector(bytes4(0x59d1d43c), bytes32(0), "xap-address-data-42161"));

    
        // Check that the address is correct.
        assertEq(uint96(uint256(bytes32(resolvedAddressData))), 200);

    }
    function test_008____resolve_contenthash_________ResolveTheContentHashOfAXAPAdress() public {

        // Check that the resolver can resolve the address.
        (bytes memory resolvedContentHash, ) = 
        resolver.resolve(bytes("\x0axyz-driver\x03xap\x03eth\x00"), 
            abi.encodeWithSelector(bytes4(0xbc1c58d1), bytes32(0)));

        // Data URL for the contenthash.
        string memory beforeData = "data:text/html,%3Cbr%3E%3Ch2%3E%3Cdiv%20style%3D%22text-align%3Acenter%3B%20font-family%3A%20Arial%2C%20sans-serif%3B%22%3EXAP%20Account%20Owner%3A%20";

        string memory delimter = "%3Cbr%3EXAP%20Account%20Data%3A%20"; 
        string memory afterData = "%3C%2Fh2%3E%3C%2Fdiv%3E";

        string memory outString = string.concat(beforeData,Strings.toHexString(account));
        outString = string.concat(outString,delimter);
        outString = string.concat(outString,Strings.toString(100));
        outString = string.concat(outString,afterData);

        // Check that the address is correct.
        bool areEqual = equalStrings(string(resolvedContentHash), outString);
        assertEq(areEqual, true);
    }    

    function test_009____resolve_contenthash_________ResolveTheContentHashOfRootXAPETH() public {

        // Check that the resolver can resolve the address.
        (bytes memory resolvedContentHash, ) = 
        resolver.resolve(bytes("\x03xap\x03eth\x00"), 
            abi.encodeWithSelector(bytes4(0xbc1c58d1), bytes32(0)));

        // Check that the address is correct.
        assertTrue( equalStrings(string(resolvedContentHash), "test content hash value"));
    }

    // Test the supportsInterface function.
    function test_010____supportsInterface___________SupportsCorrectInterfaces() public {

        // Check for the ISubnameWrapper interface.  
        assertEq(resolver.supportsInterface(type(IXAPResolver).interfaceId), true);

        // Check for the ISubnameWrapper interface.  
        assertEq(resolver.supportsInterface(type(IExtendedResolver).interfaceId), true);

        // Check for the IERC165 interface.  
        assertEq(resolver.supportsInterface(type(IERC165).interfaceId), true);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equalStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}