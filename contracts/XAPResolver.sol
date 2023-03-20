//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {IExtendedResolver} from "./IExtendedResolver.sol";
import {IXAPRegistry} from "./IXAPRegistry.sol";
import {IXAPResolver} from "./IXAPResolver.sol";
import {BytesUtilsXAP} from "./BytesUtilsXAP.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error CannotResolve(bytes4 selector);


contract XAPResolver is ERC165, IXAPResolver, IExtendedResolver{

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

    constructor (IXAPRegistry _xap) {
        xap = _xap;
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
        if (selector == 0xf1cb7e06) {

            // Decode the ABI encoded function call (data).
            // Save the coin type and not the function selector or node.
            ( , uint256 cointype_ChainId) = abi.decode(data[4:], (bytes32, uint256));

            // XAP only supports EVM chains. 
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

            // Get the label of the name
            (string memory label, ) = name.getFirstLabel();

            address resolvedAddress = xap.resolveAddress(bytes32(bytes(label)), cointype_ChainId);
            
            // Return the resolved address.
            return (abi.encodePacked(resolvedAddress), address(this)); 

        } else if (selector == 0x59d1d43c) {
            //Resolve text.

            ( ,string memory key) = abi.decode(data[4:], (bytes32, string));

            if (areStringsEqual(key, "xap-address-data-1")){

                // Get the label of the name
                (string memory label, ) = name.getFirstLabel();

                ( , uint96 addressData) = xap.resolveAddressWithData(bytes32(bytes(label)),1);
                return (abi.encodePacked(addressData), address(this));
            } else {
                revert CannotResolve(bytes4(selector));
            }
        } else if (selector == 0xbc1c58d1) {
            //Resolve contenthash.

            // Get the label of the name
            (string memory label, ) = name.getFirstLabel();

            // Get the address data of the Ethereum L1 address.
            ( address _address, uint96 accountData) = xap.getOwnerWithData(bytes32(bytes(label)));

            // Data URL for the contenthash.
            string memory beforeData = "data:text/html,%3Cbr%3E%3Ch2%3E%3Cdiv%20style%3D%22text-align%3Acenter%3B%20font-family%3A%20Arial%2C%20sans-serif%3B%22%3EEtherem%20Mainnet%20Address%3A%20";
            string memory delimter = "%3Cbr%3EXAP%20Account%20Data%3A%20"; 
            string memory afterData = "%3C%2Fh2%3E%3C%2Fdiv%3E";

            string memory outString = string.concat(beforeData,Strings.toHexString(_address));
            outString = string.concat(outString,delimter);
            outString = string.concat(outString,Strings.toString(accountData));
            outString = string.concat(outString,afterData);

            return (bytes(outString), address(this));

        } else { 
            revert CannotResolve(bytes4(selector));
        }
    }

    function areStringsEqual(string memory _a, string memory _b) private pure returns (bool) {
        return keccak256(bytes(_a)) == keccak256(bytes(_b));
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