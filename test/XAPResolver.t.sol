//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "contracts/XAPRegistry.sol";
import "contracts/IXAPRegistry.sol";
import "contracts/IXAPResolver.sol";
import "contracts/XAPResolver.sol";
import "contracts/mocks/USDOracleMock.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract XAPResolverTest is Test{

    address account = 0x0000000000000000000000000000000000003511;
    address account2 = 0x0000000000000000000000000000000000004612;

    XAPRegistry xap; 
    XAPResolver resolver;

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

        // Deploy the XAPResolver.
        resolver = new XAPResolver(xap);

        // Set up a XAP address.
        xap.setController(account, true);
        xap.registerWithData(bytes32(bytes("xyz-driver")), account, 100, 1, account2, 200); 
        assertEq(xap.resolveAddress(bytes32(bytes("xyz-driver")), 1), account2);

    }
    // Create a Subheading using an empty function.
    function test1000_________________________________________________________________________() public {}
    function test2000______________________________XAP_RESOLVER_______________________________() public {}
    function test3000_________________________________________________________________________() public {}

    function test_001____resolve_addr________________ResolveAnXAPAdressAsENSSubname() public {

        // Check that the resolver can resolve the address.
        (bytes memory resolvedAddress, ) = 
            resolver.resolve(bytes("\x0axyz-driver\x03xap\x03eth"), 
                abi.encodeWithSelector(bytes4(0xf1cb7e06), bytes32(0), uint256(1)));


        // Check that the address is correct.
        assertEq(address(bytes20(resolvedAddress)), account2);
    }

    function test_002____resolve_text________________ResolveTheAccountDataOfAXAPAdress() public {

        // Check that the resolver can resolve the address.
        (bytes memory resolvedAccountData, ) = 
            resolver.resolve(bytes("\x0axyz-driver\x03xap\x03eth"), 
                abi.encodeWithSelector(bytes4(0x59d1d43c), bytes32(0), "xap-account-data"));


        // Check that the address is correct.
        assertEq(uint96(bytes12(resolvedAccountData)), 100);
    }

    function test_003____resolve_contenthash_________ResolveTheContentHashOfAXAPAdress() public {

        // Check that the resolver can resolve the address.
        (bytes memory resolvedContentHash, ) = 
        resolver.resolve(bytes("\x0axyz-driver\x03xap\x03eth"), 
            abi.encodeWithSelector(bytes4(0xbc1c58d1), bytes32(0)));

        // Data URL for the contenthash.
        string memory beforeData = "data:text/html,%3Cbr%3E%3Ch2%3E%3Cdiv%20style%3D%22text-align%3Acenter%3B%20font-family%3A%20Arial%2C%20sans-serif%3B%22%3EEtherem%20Mainnet%20Address%3A%20";
        string memory delimter = "%3Cbr%3EXAP%20Address%20Data%3A%20"; 
        string memory afterData = "%3C%2Fh2%3E%3C%2Fdiv%3E";

        string memory outString = string.concat(beforeData,Strings.toHexString(account2));
        outString = string.concat(outString,delimter);
        outString = string.concat(outString,Strings.toString(200));
        outString = string.concat(outString,afterData);

        // Check that the address is correct.
        bool areEqual = equalStrings(string(resolvedContentHash), outString);
        assertEq(areEqual, true);
    }    
    
    // Test the supportsInterface function.
    function test_004____supportsInterface___________SupportsCorrectInterfaces() public {

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