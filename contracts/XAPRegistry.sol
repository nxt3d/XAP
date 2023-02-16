//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Controllable} from "./Controllable.sol";
import {Normalize} from "./Normalize.sol";
import {IXAPRegistry} from "./IXAPRegistry.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

error Unauthorized(bytes32 name);
error NotAvailable(bytes32 name);
error AccountImmutable(bytes32 name, uint256 chainId, address account);
error CannotSetOwnerToZeroAddress();

contract XAPRegistry is IXAPRegistry, ERC165, Controllable {

    using Normalize for bytes32;

    struct Record {

        uint256 owner;
        // A mapping of chain ids to addresses and data (stored as a single uint256). 
        mapping(uint256=>uint256) addresses;

    }

    /**
     * A mapping of names to records.
     * name => Record
     */
    mapping(bytes32=>Record) records;

    /**
     * A mapping of operators. An address that is authorized for an address
     * may make any changes to the name that the owner could, but may not update
     * the set of authorisations.
     * owner => operator
     */
    mapping(address => address) private _operatorApprovals;

    /**
     * A mapping of delegates. The delegate that is set by an owner
     * for a name may make changes to the name's resolver, but may not update
     * the set of token approvals.
     * (owner, name) => delegate
     */
    mapping(address => mapping(bytes32 => address)) private _tokenApprovals; 

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator
    );

    // Logged when a delegate is approved or  an approval is revoked.
    event Approved(
        address owner,
        bytes32 indexed name,
        address indexed delegate
    );

    /**
     * @dev Allows for approving a single operator.
     */
    function setApprovalForAll(address operator) external {
        require(
            msg.sender != operator,
            "Setting approval status for self"
        );

        _operatorApprovals[msg.sender] = operator;
        emit ApprovalForAll(msg.sender, operator);
    }

    /**
     * @dev Check to see if the operator is approved for all.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[account] == operator;
    }

    /**
     * @dev Approve a delegate to be able to updated records on a name.
     */
    function approve(bytes32 name, address delegate) external {
        require(
            msg.sender != delegate,
            "Setting delegate status for self"
        );

        _tokenApprovals[msg.sender][name] = delegate;
        emit Approved(msg.sender, name, delegate);
    }

    /**
     * @dev Check to see if the delegate has been approved by the owner for the name.
     */
    function isApprovedFor(address owner, bytes32 name, address delegate)
        public
        view
        returns (bool)
    {
        return _tokenApprovals[owner][name] == delegate;
    }


    /**
    * @dev The function registers a name with the owner address.
    * @param name The name to be registered.
    * @param _owner The account to be registered as the owner of the name.
    * @param chainId The chainId on which the name will be registered.
    * @param _address The resolved account for a specific chainId.
     */

    function register(
        bytes32 name, 
        address _owner, 
        uint256 chainId, 
        address _address
    ) external onlyController{

        // Check to make sure the name has not already been registered. 
        (address oldOwner, ) = _decodeData(records[name].owner); 
        if (oldOwner != address(0)){
            revert NotAvailable(name);
        }

        records[name].owner = _packData(_owner, 0);
        records[name].addresses[chainId] = _packData(_address, 0);

    }
    /**
    * @dev The function registers a name with the owner address.
    * @param name The name to be registered.
    * @param _owner The account to be registered as the owner of the name.
    * @param accountData The aux data of the owner delegate.
    * @param chainId The chainId on which the name will be registered.
    * @param _address The resolved account for a specific chainId.
    * @param addressData The aux data of the address delegate.
     */

    function registerWithData(
        bytes32 name, 
        address _owner, 
        uint96 accountData, 
        uint256 chainId, 
        address _address,
        uint96 addressData 
    ) external onlyController{

        // Check to make sure the name has not already been registered. 
        (address oldOwner, ) = _decodeData(records[name].owner); 
        if (oldOwner != address(0)){
            revert NotAvailable(name);
        }

        records[name].owner = _packData(_owner, accountData);
        records[name].addresses[chainId] = _packData(_address, addressData);

    }

    /**
    * @dev The function registers an address with a name on the specified chain.
    * @param name The name to be registered.
    * @param chainId The chainId on which the address will be registered.
    * @param _address The account to be registered with the name.
    */ 
    function registerAddress(bytes32 name, uint256 chainId, address _address) external onlyAuthorized(name){

        // Make sure the address is not set. Accounts are immutable. 
        address account = resolveAddress(name, chainId);
        if( account != address(0)){
            revert AccountImmutable(name, chainId, account);
        }
        records[name].addresses[chainId] = _packData(_address, 0);

    }

    /**
    * @dev The function registers an address with a name on the specified chain.
    * @param name The name to be registered.
    * @param chainId The chainId on which the address will be registered.
    * @param _address The account to be registered with the name.
    * @param addressData The auxiliary data of the address.
    */ 
    function registerAddressWithData(
        bytes32 name, 
        uint256 chainId, 
        address _address,
        uint96 addressData
    ) external onlyAuthorized(name){

        // Make sure the address is not set. Account addresses are immutable.

        address account = resolveAddress(name, chainId);
        if( account != address(0)){
            revert AccountImmutable(name, chainId, account);
        }
        records[name].addresses[chainId] = 
            _packData(_address, addressData);

    }

    /**
    * @dev The function sets the owner of a name.
    * @param name The name for which the owner will be set.
    * @param _address The address to be set as the owner of the name.
    */    

    function setOwner(bytes32 name, address _address) external onlyAuthorized(name){

        // Make sure the address is not the zero address.
        if (_address == address(0)){
            revert CannotSetOwnerToZeroAddress();
        }

        // Retrieve the accountData.
        (, uint96 accountData) = _decodeData(records[name].owner);
        records[name].owner = _packData(_address, accountData);

    }

    /**
    * @dev The function sets the account data.
    * @param name The name for which the owner will be set.
    * @param data The auxiliary data of the account.
    */    

    function setAccountData(bytes32 name, uint96 data) external onlyAuthorized(name){

        //Retrive the owner address.
        (address _address, ) = _decodeData(records[name].owner);
        records[name].owner = _packData(_address, data);

    }
    
    /**
    * @dev The function sets address data of an address.
    * @param name The name to be registered.
    * @param chainId The chainId on which the address will be registered.
    * @param addressData The auxiliary data of the address.
    */    

    function setAddressData(
        bytes32 name, 
        uint256 chainId, 
        uint96 addressData
    ) external onlyAuthorized(name){

        //Retrive the address.
        (address _address, ) = _decodeData(records[name].addresses[chainId]);
        records[name].addresses[chainId] = _packData(_address, addressData);

    }

    /**
    * @dev The function resolves an address associated with a name on a specific chain.
    * @param name The name for which the address will be resolved.
    * @param chainId The chainId on which the address is registered.
    * @return The account associated with the name on the specified chain.
    */

    function resolveAddress(bytes32 name, uint256 chainId) public view returns (address){

        // resolve the address and return the account.
        // Note: if the address is not set the account will be the zero address.
        (address account, ) = _decodeData(records[name].addresses[chainId]);
        return account;

    }

    /**
    * @dev The function resolves an address associated with a name on a specific chain.
    * @param name The name for which the address will be resolved.
    * @param chainId The chainId on which the address is registered.
    * @return The account and auxiliary data associated with the name on the specified chain.
    */

    function resolveAddressWithData(
        bytes32 name, 
        uint256 chainId
    ) public view returns (address, uint96){

        // resolve the address and return the account with auxiliary data.
        // Note: If the address is not set the account and auxiliary data will be the zero address and value zero.
        return _decodeData(records[name].addresses[chainId]);

    }

    /**
    * @dev The function returns the owner of a name.
    * @param name The name for which the owner will be returned.
    * @return The owner of the name.
    */

    function getOwner(bytes32 name) public view returns (address){

        // Note: If the name has not been registered the owner will be the zero address.
        (address _owner, ) = _decodeData(records[name].owner); 
        return _owner;

    }

    /**
    * @dev The function returns the owner of a name with auxiliary data.
    * @param name The name for which the owner will be returned.
    * @return The owner of the name, and auxiliary data.
    */

    function getOwnerWithData(bytes32 name) public view returns (address, uint96){

        return _decodeData(records[name].owner);  

    }

    /**
    * @dev The function checks if a name is available for registration.
    * @param name The name to check availability for.
    * @return Boolean indicating whether the name is available for registration.
    */

    function available(bytes32 name) external view returns (bool){

        (address _owner, ) = _decodeData(records[name].owner); 
        return _owner == address(0);

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
            interfaceId == type(IXAPRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    modifier onlyAuthorized(bytes32 name){

        if (isAuthorized(name)){
            revert Unauthorized(name);
        }
        _;

    }

    function isAuthorized(bytes32 name) internal view  returns (bool) {

        address owner = getOwner(name);

        return owner == msg.sender || isApprovedForAll(owner, msg.sender) || 
            isApprovedFor(owner, name, msg.sender);
    }


    function _decodeData(uint256 data)
        internal
        pure
        returns (
            address account,
            uint96 auxData
        )
    {
        // Get the owner from the token id. 
        account = address(uint160(data));

        // Get the aux data out of the token value.
        auxData = uint96(data >> 160);
    }

    function _packData(
        address account,
        uint96 auxData
    ) internal pure returns (uint256 data) {
        data = uint256(uint160(account)) |
            uint256(auxData) << 160;
    }
}