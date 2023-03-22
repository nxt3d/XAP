//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IMutableRegistry} from "./IMutableRegistry.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Controllable} from "./Controllable.sol";

error Unauthorized(bytes32 name);
error NotAvailable(bytes32 name);
error AccountImmutable(bytes32 name, uint256 chainId, address account);
error CannotSetOwnerToZeroAddress();
error MustHaveNonZeroAddress();
error ImmutableRecord(bytes32 name, uint256 chainId, uint96 addressData);
error CannotDelegateToSelf();

contract MutableRegistry is IMutableRegistry, ERC165, Controllable{

    struct Record {

        address owner;
        // A mapping of chain ids to addresses and data (stored as a single uint256). 
        mapping(uint256 chainId => address addr) addresses;
        mapping(string key => string value) textRecords;
        bytes contentHash;

    }

    /**
     * A mapping of names to records.
     */
    mapping(bytes32 name => Record record) private records;

    /**
     * A mapping of operators. An address that is authorized for an address
     * may make any changes to the name that the owner could, but may not update
     * the set of authorisations.
     */
    mapping(address owner => address operator) private _operatorApprovals;

    /**
     * A mapping of delegates. The delegate that is set by an owner
     * for a name may make changes to the name's resolver, but may not update
     * the set of token approvals.
     */
    mapping(address owner => mapping(bytes32 name => address delegate)) private _tokenApprovals; 

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

        if(msg.sender == operator){
            revert CannotDelegateToSelf();         
        }

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

        if(msg.sender == delegate){
            revert CannotDelegateToSelf();         
        }

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
        address oldOwner = records[name].owner; 

        if (oldOwner != address(0)){
            revert NotAvailable(name);
        }

        records[name].owner = _owner;
        records[name].addresses[chainId] = _address;

    }

    /**
    * @dev The function registers a name with the owner address.
    * @param name The name to be registered.
    * @param _owner The account to be registered as the owner of the name.
    * @param contentHash The content hash of the name.
    * @param chainId The chainId on which the name will be registered.
    * @param _address The resolved account for a specific chainId.
     */

    function registerWithData(
        bytes32 name, 
        address _owner, 
        bytes memory contentHash, 
        uint256 chainId, 
        address _address
    ) external onlyController{

        // Check to make sure the name has not already been registered. 
        address oldOwner = records[name].owner; 
        
        if (oldOwner != address(0)){
            revert NotAvailable(name);
        }

        records[name].owner = _owner;
        records[name].addresses[chainId] = _address;
        records[name].contentHash = contentHash;

    }

    /**
    * @dev The function registers an address with a name on the specified chain.
    * @param name The name to be registered.
    * @param chainId The chainId on which the address will be registered.
    * @param _address The account to be registered with the name.
    */ 
    function registerAddress(bytes32 name, uint256 chainId, address _address) external onlyAuthorized(name){

        // Make sure the address is not the 0 address. 
        if(_address == address(0)){
            revert MustHaveNonZeroAddress();
        }
        records[name].addresses[chainId] = _address;

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

        records[name].owner = _address;

    }

    /**
    * @dev The function sets the account data.
    * @param name The name for which the owner will be set.
    * @param _contentHash The auxiliary data of the account.
    */    

    function setContentHash(bytes32 name, bytes memory _contentHash) external onlyAuthorized(name){

        records[name].contentHash = _contentHash;

    }

    /**
    * @dev The function sets the account data.
    * @param name The name for which the owner will be set.
    * @param key The key of the text record.
    * @param value The value of the text record.
    */    

    function setTextRecord(bytes32 name, string memory key, string memory value) external onlyAuthorized(name){

        records[name].textRecords[key] = value;

    }
    
    /**
    * @dev The function resolves an address associated with a name on a specific chain.
    * @param name The name for which the address will be resolved.
    * @param chainId The chainId on which the address is registered.
    * @return The address associated with the name on the specified chain.
    */

    function resolveAddress(bytes32 name, uint256 chainId) public view returns (address){

        // resolve the address and return the account.
        // Note: if the address is not set the account will be the zero address.
        address _address = records[name].addresses[chainId];
        return _address;

    }

    /**
    * @dev The function returns the owner of a name.
    * @param name The name for which the owner will be returned.
    * @return The owner of the name.
    */

    function getOwner(bytes32 name) public view returns (address){

        // Note: If the name has not been registered the owner will be the zero address.
        address _owner = records[name].owner; 
        return _owner;

    }

    /**
    * @dev The function checks if a name is available for registration.
    * @param name The name to check availability for.
    * @return Boolean indicating whether the name is available for registration.
    */

    function available(bytes32 name) external view returns (bool){

        address _owner = records[name].owner; 
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
            interfaceId == type(IMutableRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    //Check whether the sender is authorized to access the function.
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

}