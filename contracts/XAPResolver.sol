//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.18;

//import "forge-std/console.sol";
import {IExtendedResolver} from "./IExtendedResolver.sol";
import {IXAPRegistry} from "./IXAPRegistry.sol";
import {IXAPResolver} from "./IXAPResolver.sol";
import {BytesUtilsXAP} from "./BytesUtilsXAP.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMutableRegistry} from "./IMutableRegistry.sol";

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error CannotResolve(bytes4 selector);


contract XAPResolver is ERC165, IXAPResolver, IExtendedResolver, Ownable{

    // addr(bytes32 node, uint256 coinType) public view virtual override returns (bytes memory) 
    // => addr(bytes32,uint256) => 0xf1cb7e06
    // text(bytes32 node, string calldata key)external view virtual override returns (string memory)
    // => text(bytes32,string) => 0x59d1d43c
    // contenthash(bytes32 node) external virtual authorised(node) 
    // contenthash( bytes32 node) external view virtual override returns (bytes memory) 
    // => contenthash(bytes32) => 0xbc1c58d1

    // abc.xap.eth => 0x03616263037861700365746800

    using BytesUtilsXAP for bytes;

    IXAPRegistry public xap;

    IMutableRegistry public mutableRegistry;

    // The name of the parent name, e.g. xap.eth.
    bytes public parentName;

    constructor (IXAPRegistry _xap, IMutableRegistry _mutableRegistry, bytes memory _parentName) {
        xap = _xap;
        parentName = _parentName;
        mutableRegistry = _mutableRegistry;
    }

    function resolve(bytes calldata name, bytes calldata data)
        external
        view
        override (IExtendedResolver, IXAPResolver)
        returns (bytes memory, address)
    {

        // Read function selector from the data.
        bytes4 selector = bytes4(data[0:4]);
        // Resolve address.
        if (selector == 0xf1cb7e06 || selector == 0x3b3b57de) {

            uint256 cointype_ChainId;

            // If the selector is the addr(bytes32) function (without a coin type) then set the coin type to ETH (60).
            if (selector == 0x3b3b57de){
                cointype_ChainId = 60;
            } else {
                // selector: addr(bytes32,uint256)
                // Decode the ABI encoded function call (data).
                // Save the coin type and not the function selector or node.
                ( , cointype_ChainId) = abi.decode(data[4:], (bytes32, uint256));
            }

            // If the coin type is not ETH (60) then check to see if it is an another EVM chain, and extract the chain ID.
            if (cointype_ChainId == 60){ 
                cointype_ChainId = 1;
            } else if (cointype_ChainId > uint256(0x80000000)) {
                // if the coint type is greater than 0x80000000 then it an EVM ENS encoded chain id.
                cointype_ChainId = cointype_ChainId ^ uint256(0x80000000);
            } else {
                // If the coin type is not ETH (60) or an EVM chain then revert.
                revert CannotResolve(bytes4(selector));
            }

            // Check to see if the name is the parent name.
            if (areStringsEqual(string(name), string(parentName))){

                address mutableAddress = mutableRegistry.resolveAddress(name, cointype_ChainId);

                if (mutableAddress == address(0)){
                    // If the address is not found then revert.
                    revert CannotResolve(bytes4(selector));
                }
                return (abi.encode(mutableAddress),address(this));
            }

            // Split the name into the label and the parent name.
            (bytes memory label, bytes memory root) = bytes(name).splitBytes(name.length - parentName.length);
            
            // Remove the first byte of the label (the length of the label).
            ( , label) = label.splitBytes(1);

            // Make sure the root matches the defined parent name.
            require(areStringsEqual(string(root), string(parentName)), "Invalid root name");

            // Resolve the address of the label on the chain id.
            address resolvedAddress = xap.resolveAddress(bytes32(label), cointype_ChainId);

            if (resolvedAddress == address(0)){
                // If the address is not found then revert.
                revert CannotResolve(bytes4(selector));
            }
            
            // Return the resolved address.
            return (abi.encode(resolvedAddress), address(this)); 

        } else if (selector == 0x59d1d43c) {
            //Resolve text.

            // Strip off the function selector and decode the ABI encoded function call (data).
            ( ,string memory key) = abi.decode(data[4:], (bytes32, string));

            // Check to see if the name is the parent name.
            if (areStringsEqual(string(name), string(parentName))){

                string memory textRecord = mutableRegistry.getTextRecord(name, key);

                return (bytes(textRecord),address(this));
            }

            // Split the key into the key and chain id.
            (bytes memory keyBytes, bytes memory chainId) = bytes(key).splitBytes(17);

            // Convert the chain id to a uint256. 
            uint256 chainIdInt = chainId.bytesNumberToUint();

            // Check if the key is "xap-address-data-" and the chain id is greater than 0.
            if (areStringsEqual(string(keyBytes), "xap-address-data-") && chainIdInt > 0){

                // Split the name into the label and the parent name.
                (bytes memory label, bytes memory root) = bytes(name).splitBytes(name.length - parentName.length);
                
                // Remove the first byte of the label (the length of the label).
                ( , label) = label.splitBytes(1);

                // Make sure the root matches the defined parent name.
                require(areStringsEqual(string(root), string(parentName)), "Invalid root name");

                // Get the address data of the address of the chain id.
                ( , uint96 addressData) = xap.resolveAddressWithData(bytes32(label),chainIdInt);

                // Return the address data.
                return (abi.encode(addressData), address(this));
            } else {
                revert CannotResolve(bytes4(selector));
            }
        } else if (selector == 0xbc1c58d1) {
            //Resolve contenthash.

            // Check to see if the name is the parent name.
            if (areStringsEqual(string(name), string(parentName))){

                bytes memory contentHash = mutableRegistry.getContentHash(name);

                return (contentHash,address(this));
            }

            // Split the name into the label and the parent name.
            (bytes memory label, bytes memory root) = bytes(name).splitBytes(name.length - parentName.length);
            
            // Remove the first byte of the label (the length of the label).
            ( , label) = label.splitBytes(1);

            // Make sure the root matches the defined parent name.
            require(areStringsEqual(string(root), string(parentName)), "Invalid root name");


            // Get the address data of the Ethereum L1 address.
            ( address _address, uint96 accountData) = xap.getOwnerWithData(bytes32(label));

            // Data URL for the contenthash.
            string memory beforeData = "data:text/html,%3Cbr%3E%3Ch2%3E%3Cdiv%20style%3D%22text-align%3Acenter%3B%20font-family%3A%20Arial%2C%20sans-serif%3B%22%3EXAP%20Account%20Owner%3A%20";
            string memory delimter = "%3Cbr%3EXAP%20Account%20Data%3A%20"; 
            string memory afterData = "%3C%2Fh2%3E%3C%2Fdiv%3E";

            // Concatenate the data URL. 
            string memory outString = string.concat(beforeData,Strings.toHexString(_address));
            outString = string.concat(outString,delimter);
            outString = string.concat(outString,Strings.toString(accountData));
            outString = string.concat(outString,afterData);

            if (_address == address(0)){
                // If the address is not found then revert.
                revert CannotResolve(bytes4(selector));
            }

            // Return the data URL.
            return (bytes(outString), address(this));

        } else { 
            revert CannotResolve(bytes4(selector));
        }
    } 

    function areStringsEqual(string memory _a, string memory _b) private pure returns (bool) {
        return keccak256(bytes(_a)) == keccak256(bytes(_b));
    }

    function setParentName(bytes memory name) public onlyOwner {
        parentName = name;
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
            interfaceId == type(IXAPResolver).interfaceId ||
            interfaceId == type(IExtendedResolver).interfaceId ||
            super.supportsInterface(interfaceId);
    }



}