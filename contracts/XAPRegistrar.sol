//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.17;

import "forge-std/console.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Normalize} from "./Normalize.sol";
import {IXAPRegistry} from "./IXAPRegistry.sol";
import {IXAPRegistrar} from "./IXAPRegistrar.sol";
import {ERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {IAggregatorInterface} from "./IAggregatorInterface.sol";

error MinCharsTooLow();
error UnexpiredCommitment(bytes32 commitment);
error CommitmentTooOld(bytes32 commitment);
error CommitmentTooNew(bytes32 commitment);
error MinCommitmentAgeTooHigh();
error MaxCommitmentAgeTooLow();
error NoNameFoundAfterNAttempts(uint256 maxLoops);
error NameNotNormalized(bytes32 name);
error InsufficientValue();
error MinCommitmentGreaterThanMaxCommitment();
error CannotSetNewCharLengthAmounts();

contract XAPRegistrar is IXAPRegistrar, ERC165, Ownable{

    IXAPRegistry public xap;
    using Normalize for bytes32;

    // Chainlink oracle address
    IAggregatorInterface public immutable usdOracle;
    
    // The required number of numbers, letters, and characters in a name.
    uint32 public minNumbers;
    uint32 public minLetters;
    uint32 public minCharacters;

    // The minimum and maximum age of a commitment before it can be used to register a name.
    uint256 public minCommitmentAge;
    uint256 public maxCommitmentAge;

    // Save the pricing for each character (1-6) in wei. 7-10 are free to register.
    uint256[] public charAmounts;

    // A mapping of commitments to the date stamps.
    mapping(bytes32 => uint256) public commitments;

    constructor(IXAPRegistry _xap, IAggregatorInterface _usdOracle){

        xap = _xap;

        // The minimum number of numbers, letters, and characters in a name.
        // This can be changed by the owner of the contract.
        minNumbers = 3;
        minLetters = 3;
        minCharacters = 7;

        minCommitmentAge = 1 minutes;
        maxCommitmentAge = 7 days;

        usdOracle = _usdOracle;
    }

    /**
    * @dev The function creates a commitment hash of a name, owner and a secret.
    * @param name The name to be included in the commitment.
    * @param owner The address to be included in the commitment.
    * @param secret A secret to be included in the commitment.
    * @return The commitment hash created from the name, owner and secret.
    */

    function makeCommitment(
        bytes32 name,
        address owner,
        bytes32 secret
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    name,
                    owner,
                    secret
                )
            );
    }

    /**
    * @dev The function commits a commitment hash of a name, owner and a secret.
    * @param commitment The commitment hash to be committed.
    */

    function commit(bytes32 commitment) public {
        // Check to make sure the commitment has expired (or does not exist). 
        if (commitments[commitment] + maxCommitmentAge >= block.timestamp) {
            revert UnexpiredCommitment(commitment);
        }
        commitments[commitment] = block.timestamp;
    }

    /**
    * @dev The function claims a name and registers it.
    * @param name The name to be claimed.
    * @param chainId The chainId on which the name will be registered.
    * @param _address The address to be registered as the owner of the name.
    */

    function claim(
        bytes32 name, 
        uint chainId, 
        address _address,
        bytes32 secret
        ) external payable{

        (bool isNormal, uint256 nameLength) = name.isNormalized(minNumbers, minLetters, minCharacters);

        if(!isNormal){
            revert NameNotNormalized(name);
        }

        // check to make sure nameLength is not greater than the length of the charAmounts array
        // if it is, then set the amount to charAmounts[0]

        uint256 price;
        if(nameLength >= charAmounts.length){
           price = usdToWei(charAmounts[0]);
        } else {
            price = usdToWei(charAmounts[nameLength]);
        }

        if (msg.value < price) {
            revert InsufficientValue();
        }

        // Check the commitment to make sure its valid.
        _burnCommitment(
            makeCommitment(
                name,
                msg.sender,
                secret
            )
        );

       // Register an available name 
        xap.register(name, msg.sender, chainId, _address);

        // If the the sender sent more ETH than necessary send the remainder back.
        if (msg.value > (price)) {
            payable(msg.sender).transfer(
                msg.value - price
            );
        }

    }   

    /**
    * @dev The function sets the minimum number of required numbers, letters and characters for a name.
    * @param _minNumbers The minimum number of numbers required in a name.
    * @param _minLetters The minimum number of letters required in a name.
    * @param _minCharacters The minimum number of characters required in a name.
    */

    function setMinimumCharacters(uint32 _minNumbers, uint32 _minLetters, uint32 _minCharacters) public onlyOwner{

        // The minimum number of characters must be greater than or equal to the 
        // sum of the minimum number of letters and numbers.
        if(minNumbers + minLetters > minCharacters){
            revert MinCharsTooLow();
        }

        minNumbers = _minNumbers;
        minLetters = _minLetters;
        minCharacters = _minCharacters;

    }

    /**
    * @notice Set the pricing for subname lengths.
    * @param _charAmounts An array of amounst for each characer length.
    */  

     function setPricingForAllLengths(
        uint256[] calldata _charAmounts
    ) public onlyOwner{

        // Clear the old dynamic array out
        delete charAmounts;

        // Set the pricing for names.
        charAmounts = _charAmounts;
        
    }

    /**
     * @notice Set a price for a single character length, e.g. three characters.
     * @param charLength The character length, e.g. 3 would be for three characters. Use 0 for the default amount.
     * @param charAmount The amount in USD/year for a character count, e.g. amount for three characters.
     */
    function updatePriceForCharLength(
        uint16 charLength,
        uint256 charAmount
    ) public onlyOwner{

        // Check that the charLength is not greater than the last index of the charAmounts array.
        if (charLength > charAmounts.length-1){
            revert CannotSetNewCharLengthAmounts();
        }
        charAmounts[charLength] = charAmount;
    }

    /**
     * @notice Adds a price for the next character length, e.g. three characters.
     * @param charAmount The amount in USD/sec. (with 18 digits of precision) 
     * for a character count, e.g. amount for three characters.
     */
    function addNextPriceForCharLength(
        uint256 charAmount
    ) public onlyOwner{

        charAmounts.push(charAmount);
    }

    /**
     * @notice Get the last length for a character length that has a price (can be 0), e.g. three characters.
     * @return The length of the last character length that was set.
     */
    function getLastCharIndex() public view returns (uint256) {
        return charAmounts.length - 1;
    }

    /**
    * @dev The function sets the minimum and maximum age of a commitment before it can be used to register a name.
    * @param _minCommitmentAge The minimum age of a commitment.
    * @param _maxCommitmentAge The maximum age of a commitment.
    */

    function setMinMaxCommitmentAge(uint256 _minCommitmentAge, uint256 _maxCommitmentAge) public onlyOwner{

        if (_minCommitmentAge >= _maxCommitmentAge){
            revert MinCommitmentGreaterThanMaxCommitment();
        }

        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    /**
    * @dev The function returns the minimum number of required numbers, letters and characters for a name.
    * @return A tuple containing the minimum number of required numbers, letters, and characters for a name.
    */

    function getMinimums() public view returns(uint32,uint32,uint32){
        return (minNumbers, minLetters, minCharacters);
    }

    /**
    * @dev The function creates random names until it finds an available name.
    * @param maxLoops The maximum number of times to try to find an available name.
    * @return A random name that is available.
    */

    function getRandomName(
        uint256 maxLoops, 
        uint256 _minNumbers, 
        uint256 _minLetters, 
        uint256 _numChars,
        uint256 _salt
    ) 
        public view returns (bytes32) {
        // Generate the random name using only [a-z0-9] or [0x61-0x7a, 0x30-0x39]

        // Try to find a name at most maxLoops times.
        for (uint256 count = 0; count < maxLoops; count++) {

            bytes32 randomName;

            uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, count, _salt)));

            for (uint256 i = 0; i < _numChars; i++) {
                if (randomNumber % 2 == 0) {
                    // The first character will be a number
                    randomName = randomName | (bytes32(bytes1(uint8(48 + (randomNumber % 10)))) >> (i * 8));
                    randomNumber = randomNumber >> 8;
                } else {
                    // The first character will be a letter
                    randomName = randomName | (bytes32(bytes1(uint8(97 + (randomNumber % 26)))) >> (i * 8));
                    randomNumber = randomNumber >> 8;
                }

                randomNumber = randomNumber >> 8;
            }

            (bool isNormal, ) = randomName.isNormalized(_minNumbers, _minLetters, 1);

            //check if the name is available
            if (xap.available(randomName) && isNormal) {
                return randomName;
            }
        }
        // If we can't find a name, revert.
        revert NoNameFoundAfterNAttempts(maxLoops);
    }
    
    /**
    * @dev Allows the contract owner to withdraw the entire balance of the contract.
    * @notice This function can only be called by the contract owner.
    * @notice Before calling this function, ensure that the contract balance is greater than zero.
    */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Contract balance must be greater than zero.");
        address payable owner = payable(msg.sender);
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Withdrawal failed.");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IXAPRegistrar).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
    * @dev Converts USD to Wei. 
    * @param amount The amount of USD to be converted to Wei.
    * @return The amount of Wei.
    */
    function usdToWei(uint256 amount) internal view returns (uint256) {
        uint256 ethPrice = uint256(usdOracle.latestAnswer());
        return (amount * 1e8) / ethPrice;
    }

    /**
    * @dev The function checks and then burns a commitment hash.
    * @param commitment The commitment hash to be checked and then burned.
    */

    function _burnCommitment(
        bytes32 commitment
    ) internal {
        // Require an old enough commitment.
        if (commitments[commitment] + minCommitmentAge > block.timestamp) {
            revert CommitmentTooNew(commitment);
        }

        // If the commitment is too old 
        if (commitments[commitment] + maxCommitmentAge <= block.timestamp) {
            revert CommitmentTooOld(commitment);
        }

        delete (commitments[commitment]);
    }

}