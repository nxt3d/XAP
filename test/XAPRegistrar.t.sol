//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "contracts/XAPRegistry.sol";
import "contracts/IXAPRegistry.sol";
import "contracts/XAPRegistrar.sol";
import "contracts/IXAPRegistrar.sol";
import "contracts/mocks/USDOracleMock.sol";

contract XAPRegistrytxt is Test{

    address account = 0x0000000000000000000000000000000000003511;
    address account2 = 0x0000000000000000000000000000000000004612;

    XAPRegistry xap; 
    XAPRegistrar xapRegistrar;

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

        // Deploy the XAPRegistrar.
        xapRegistrar = new XAPRegistrar(xap, usdOracle);
        
        // Set the pricing for the subname registrar. 
        uint256[] memory charAmounts = new uint256[](10);
        charAmounts[0] = 0; // (≈$5/year) calculated as $/sec with 18 decimals.
        // skip 1 and 2 character names becuase they are reseved.
        charAmounts[3] = 12000 * 1e18;
        charAmounts[4] = 8000 * 1e18;
        charAmounts[5] = 200 * 1e18;
        charAmounts[6] = 100 * 1e18;
        charAmounts[7] = 50 * 1e18;
        charAmounts[8] = 25 * 1e18;
        charAmounts[9] = 15 * 1e18;

        xapRegistrar.setPricingForAllLengths(
            charAmounts
        );

        // Make the xap registrar the controller.
        xap.setController(address(xapRegistrar), true);

    }
    // Create a Subheading using an empty function.
    function test1000_________________________________________________________________________() public {}
    function test2000______________________________XAP_REGISTRAR______________________________() public {}
    function test3000_________________________________________________________________________() public {}

    // Test the function 'makeCommitment'.
    function test_001____MakeCommitment______________TheCommitmentWasCreatedCorrectly(bytes32 name, bytes32 salt) public {

        // Make a commitment to register a name.    
        bytes32 commitment = xapRegistrar.makeCommitment(bytes32(bytes("addr-123")), account, bytes32(bytes5(0x1234567890))); 

        // Make a new commitment by encoding the parameters and taking the keccak256 hash.
        bytes32 commitment2 = keccak256(abi.encode(bytes32(bytes("addr-123")), account, bytes32(bytes5(0x1234567890))));

        // Check to make sure the commitments are the same.
        assertEq(commitment, commitment2);

        // Make a commitment to register a name with fuzzing this time.    
        bytes32 commitmentFuzz = xapRegistrar.makeCommitment(name, account, salt); 

        // Make a new commitment by encoding the parameters and taking the keccak256 hash.
        bytes32 commitment2Fuzz = keccak256(abi.encode(name, account, salt));

        // Check to make sure the commitments are the same.
        assertEq(commitmentFuzz, commitment2Fuzz);
    }

    // Test the function 'commmit'.
    function test_002____Commit______________________CommitWasSavedWithTheTimestamp(bytes32 name, bytes32 salt) public {

        // Make a commitment to register a name.    
        bytes32 commitment = xapRegistrar.makeCommitment(bytes32(bytes("addr-123")), account, bytes32(bytes5(0x1234567890))); 

        // Save the commitment.
        xapRegistrar.commit(commitment);

        // Check to make sure the commitment is correct.
        assertEq(xapRegistrar.commitments(commitment), block.timestamp);

         // Make a commitment to register a name with fuzzing this time.    
        bytes32 commitmentFuzz = xapRegistrar.makeCommitment(name, account, salt); 

        // Save the commitment.
        xapRegistrar.commit(commitmentFuzz);

        // Check to make sure the commitment is correct.
        assertEq(xapRegistrar.commitments(commitmentFuzz), block.timestamp);       
    }

    // Test the function 'claim'.
    function test_003____Claim_______________________RegisterAXAPAddress() public {

        // Make a commitment to register a name.    
        bytes32 commitment = xapRegistrar.makeCommitment(bytes32(bytes("addr-123")), account, bytes32(bytes5(0x1234567890))); 

        // save the account balance. 
        uint256 accountBalance = account.balance;

        // Save the commitment.
        xapRegistrar.commit(commitment);

        // Move forward 60 seconds in time. 
        skip(60);

        // Register the name, sending 1 ETH, which is more ether than needed. A refund will occur if successful.
        xapRegistrar.claim{value: 1000000000000000000}(bytes32(bytes("addr-123")), uint96(bytes12(bytes("this is text"))), block.chainid, account2, uint96(1234567890), bytes32(bytes5(0x1234567890)));

        // Check to make sure the correct amount of ether was sent to the registrar.
        assertEq(address(xapRegistrar).balance, 15295758792002153);

        // Check to make sure the balance of 'account' is correct.
        assertEq(account.balance, accountBalance - 15295758792002153);

        // Check to make sure the owner is correct.
        assertEq(xap.getOwner(bytes32(bytes("addr-123"))), account);

        // Check to make sure the address is correct.
        assertEq(xap.resolveAddress(bytes32(bytes("addr-123")), block.chainid), account2);
    }

    // Test the function 'claim'.
    function test_004____Claim_______________________ClaimFunctionFailsWithBadNames() public {

        // The default minimum length is 7 chacaters.
        // The default maximum length is 32 chacaters.
        // The degault minimum number of letters is 3.
        // The default minimum number of numbers is 3.

        ///////////// Names that should revert /////////////
        // A name with two dashes (1).
        registerBadName(bytes32(bytes("addr--123")));

        // A name with two dashes (2).
        registerBadName(bytes32(bytes("1addr--")));

        // A name with dash at the front.
        registerBadName(bytes32(bytes("-addr123")));

        // A name with dash at the back.
        registerBadName(bytes32(bytes("addr123-")));

        // A name with too few characters.
        registerBadName(bytes32(bytes("addr12")));

        // A name with too few letters.
        registerBadName(bytes32(bytes("1234567")));

        // A name with too few numbers.
        registerBadName(bytes32(bytes("abcdefg")));

        // A name with no characters.
        registerBadName(bytes32(bytes("")));

        // A name with too many characters.
        registerBadName(bytes32(bytes("123456789012345678901234567890123")));

        // A name with non letters or number characters.
        registerBadName(bytes32(bytes("addr-123!")));

        // A name with null characters (1).
        registerBadName(bytes32(bytes("\x00addr123\x00")));

        // A name with null characters (2).
        registerBadName(bytes32(bytes("addr\x00123")));

        // A name with spaces.
        registerBadName(bytes32(bytes("addr 123")));

        // A name with capital letters.
        registerBadName(bytes32(bytes("ADDR123")));

        // A name with underbar.
        registerBadName(bytes32(bytes("addr_123")));

        // A name with a lattin n with a tilde.
        registerBadName(bytes32(bytes("addr\xf1123")));
        
        ///////////// Names that should NOT revert /////////////
        // A name with a number at the front.
        registerName(bytes32(bytes("1addr123")));

        // A name with a number at the back.
        registerName(bytes32(bytes("addr1231")));

        // A name with a number in the middle.
        registerName(bytes32(bytes("addr1-23")));

        // A name with lots of dashes.
        registerName(bytes32(bytes("addr-1-2-3")));

    }

    function registerName(bytes32 name) internal {

        // Make a commitment to register a name.    
        bytes32 commitment = xapRegistrar.makeCommitment(name, account, bytes32(bytes5(0x1234567890))); 

        // Save the commitment.
        xapRegistrar.commit(commitment);

        // Move forward 60 seconds in time. 
        skip(60);

        // Register the name, sending 1 ETH, which is more ether than needed. A refund will occur if successful.
        xapRegistrar.claim{value: 1000000000000000000}(name, uint96(bytes12(bytes("this is text"))), block.chainid, account2, uint96(1234567890), bytes32(bytes5(0x1234567890)));

        assertEq(xap.getOwner(name), account);
    }
    function registerBadName(bytes32 name) internal {

        // Make a commitment to register a name.    
        bytes32 commitment = xapRegistrar.makeCommitment(name, account, bytes32(bytes5(0x1234567890))); 

        // Save the commitment.
        xapRegistrar.commit(commitment);

        // Move forward 60 seconds in time. 
        skip(60);

        vm.expectRevert( abi.encodeWithSelector(NameNotNormalized.selector, name));
        // Register the name, sending 1 ETH, which is more ether than needed. A refund will occur if successful.
        xapRegistrar.claim{value: 1000000000000000000}(name, uint96(bytes12(bytes("this is text"))), block.chainid, account2, uint96(1234567890), bytes32(bytes5(0x1234567890)));
    }
    

    // Test the function 'setMinimumCharacters'.
    function test_005____SetMinimumCharacters________MinimumCharacterValuesAreSet() public {

        // Set the minimum letters to 1.
        // Set the minimum numbers to 1.
        // Set the minimum characters to 20.
        xapRegistrar.setMinimumCharacters(1,1,20);

        // Check to make sure the minimum characters is correct.
        assertEq(xapRegistrar.minLetters(), 1);
        assertEq(xapRegistrar.minNumbers(), 1);
        assertEq(xapRegistrar.minCharacters(), 20);

        // Set the minimum characters to 0

        xapRegistrar.setMinimumCharacters(0, 0, 0);

        // Check to make sure the minimum characters is correct.
        assertEq(xapRegistrar.minLetters(), 0);
        assertEq(xapRegistrar.minNumbers(), 0);
        assertEq(xapRegistrar.minCharacters(), 0);

        // Register a single letter name
        registerName("a");

        // Register a single letter name
        registerName("1");

        // Register a name with no characters
        registerBadName("");

    }

    // Test the function 'setPricingForAllLengths'.
    function test_006____SetPricingForAllLengths_____PricesAreSetForLengths() public {

        // Set the pricing for the subname registrar. 
        uint256[] memory charAmounts = new uint256[](10);
        charAmounts[0] = 0; // $USD amount with 18 decimals.
        // skip 1 and 2 character names because they are reseved.
        charAmounts[3] = 120 * 1e18;
        charAmounts[4] = 80 * 1e18;
        charAmounts[5] = 20 * 1e18;
        charAmounts[6] = 10 * 1e18;
        charAmounts[7] = 5 * 1e18;
        charAmounts[8] = 2 * 1e18;
        charAmounts[9] = 1 * 1e18;

        xapRegistrar.setPricingForAllLengths(
            charAmounts
        );

        // Check to make sure the pricing is correct.
        assertEq(xapRegistrar.charAmounts(3), 120 * 1e18);
        assertEq(xapRegistrar.charAmounts(4), 80 * 1e18);
        assertEq(xapRegistrar.charAmounts(5), 20 * 1e18);
        assertEq(xapRegistrar.charAmounts(6), 10 * 1e18);
        assertEq(xapRegistrar.charAmounts(7), 5 * 1e18);
        assertEq(xapRegistrar.charAmounts(8), 2 * 1e18);
        assertEq(xapRegistrar.charAmounts(9), 1 * 1e18);
    }

    // Test the function 'updatePriceForCharLength'.
    function test_007____UpdatePriceForCharLength____PriceIsUpdated() public {

        // Update the price for 3 character names.
        xapRegistrar.updatePriceForCharLength(3, 100000 * 1e18);

        // Check to make sure the pricing is correct.
        assertEq(xapRegistrar.charAmounts(3), 100000 * 1e18);
    }

    // Test the function 'addNextPriceForCharLength'.
    function test_008____AddNextPriceForCharLength___PriceIsAdded() public {

        // Add the next price .
        xapRegistrar.addNextPriceForCharLength(100000 * 1e18);

        // Check to make sure the pricing is correct.
        assertEq(xapRegistrar.charAmounts(xapRegistrar.getLastCharIndex()), 100000 * 1e18);
    }

    // Test the function 'getLastCharIndex'.
    function test_009____GetLastCharIndex____________ReturnsTheLastCharIndex() public {

        // Check to make sure the last char index is correct.
        assertEq(xapRegistrar.getLastCharIndex(), 9);
        
        // Add the next price .
        xapRegistrar.addNextPriceForCharLength(7 * 1e18);

        // Check to make sure the last char index is correct.
        assertEq(xapRegistrar.getLastCharIndex(), 10);
        
    }

    // Test the function 'setMinMaxCommitmentAge'.
    function test_010____SetMinMaxCommitmentAge______MinMaxCommitmentAgeIsSet() public {

        // Set the minimum commitment age to 1 second.
        // Set the maximum commitment age to 1 year.
        xapRegistrar.setMinMaxCommitmentAge(1, 31536000);

        // Check to make sure the minimum commitment age is correct.
        assertEq(xapRegistrar.minCommitmentAge(), 1);

        // Check to make sure the maximum commitment age is correct.
        assertEq(xapRegistrar.maxCommitmentAge(), 31536000);
    }

    // Test the function 'getMinimums'.
    function test_011____GetMinimums_________________ReturnsTheMinimums() public {

        // Set the minimum letters to 1.
        // Set the minimum numbers to 1.
        // Set the minimum characters to 20.
        xapRegistrar.setMinimumCharacters(1,1,20);

        // Get the minimums.
        (uint256 minLetters, uint256 minNumbers, uint256 minCharacters) = xapRegistrar.getMinimums();

        // Check to make sure the minimums are correct.
        assertEq(minLetters, 1);
        assertEq(minNumbers, 1);
        assertEq(minCharacters, 20);

    }

    // Test the function 'getRandomName'
    /* 
        function getRandomName(
        uint256 maxLoops, 
        uint256 _minNumbers, 
        uint256 _minLetters, 
        uint256 _minCharacters,
        uint256 _maxChars
    ) 
    */
    function test_012____GetRandomName_______________ReturnsARandomName() public {

        for (uint256 i = 0; i < 1000; i++) {

            //getRandomName( maxLoops, _minNumbers, _minLetters, _numChars, _salt)

            // Get a random name.
            // This function reverts if a name can't be found
            bytes32 randomName = xapRegistrar.getRandomName(20, 3, 3, 7, i);
            registerName(randomName);

        }

    }

    // Test the function 'withdraw'.
    function test_013____Withdraw____________________WithdrawsTheBalance() public {

        // Make a commitment to register a name.    
        bytes32 commitment = xapRegistrar.makeCommitment(bytes32(bytes("addr-123")), account, bytes32(bytes5(0x1234567890))); 

        // save the account balance. 
        uint256 accountBalance = account.balance;

        // Save the commitment.
        xapRegistrar.commit(commitment);

        // Move forward 60 seconds in time. 
        skip(60);

        // Register the name, sending 1 ETH, which is more ether than needed. A refund will occur if successful.
        xapRegistrar.claim{value: 1000000000000000000}(bytes32(bytes("addr-123")), uint96(bytes12(bytes("this is text"))), block.chainid, account2, uint96(1234567890), bytes32(bytes5(0x1234567890)));

        // Check to make sure the correct amount of ether was sent to the registrar.
        assertEq(address(xapRegistrar).balance, 15295758792002153);

        // Check to make sure the balance of 'account' is correct.
        assertEq(account.balance, accountBalance - 15295758792002153);

        // Withdraw the balance.
        xapRegistrar.withdraw();
        assertEq(address(xapRegistrar).balance, 0);
        assertEq(account.balance, accountBalance);
    }

    // Test the function 'supportsInterface'.
    function test_014____SupportsInterface___________ReturnsTrue() public {

        // Check to make sure the interface is supported.
        assertEq(xapRegistrar.supportsInterface(type(IXAPRegistrar).interfaceId), true);

        // Check to make sure the interface is supported.
        assertEq(xapRegistrar.supportsInterface(type(IERC165).interfaceId), true);
    }
}