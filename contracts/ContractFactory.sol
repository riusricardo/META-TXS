pragma solidity 0.4.24;

import "./libraries/openzeppelin/migrations/Initializable.sol";
import "./libraries/openzeppelin/lifecycle/Destructible.sol";
import "./libraries/openzeppelin/AddressUtils.sol";

/// @title Factory that creates new contracts from loaded bytecode.
/// @author Ricardo Rius - <ricardo@rius.info>
contract ContractFactory is Initializable,Destructible {

    /*
     FUNCTION SIGNATURES
    */
    bytes4 private constant CONTRACT_INIT_FSIG = bytes4(keccak256("initialize(address)"));

    /*
     STATE VARIABLES
    */
    uint public creationTime;
    address public registry;
    bool internal locked;
    bytes internal bytecode;

    /*
     CONSTRUCTOR
    */
    constructor() public {
        bytecode = hex"0000000000000000000000000000000000000000";
        registry = address(0);
        locked = false;
        creationTime = block.timestamp;
    }

    /*
     EVENTS
    */
    event ContractDeployed (
        address emitter, 
        address deployedAddress
    );
    event BytecodeChanged (
        address owner, 
        string message
    );
    event ContractLocked (
        address owner, 
        string message
    );

    /*
     MODIFIERS
    */
    /// @dev Verifies if the contract has not been manually locked.
    modifier ifNotLocked(){
        if(!locked){
            _;
        } else{
            revert(", contract locked.");
        }
    }

    /// @dev Verifies the required time to automatically lock the contract.
    /// @param _time time until the modifier locks.
    modifier lockAfter(uint _time) {
        require(block.timestamp < (creationTime + _time),", the function is locked by time.");
        _;
    }
    
    /*
    EXTERNAL FUNCTIONS
    */
    /// @dev Only owner can retrieve the loaded bytecode.
    function getBytecode() external view onlyOwner returns(bytes){
        return bytecode;
    }

    /// @dev Set registry address.
    /// @param _registry address.
    function initialize(address _registry) external isInitializer ifNotLocked{
        require(registry == address(0),", registry set.");
        require(AddressUtils.isContract(_registry), ", cannot set a proxy implementation to a non-contract address");
        registry = _registry;
    }
    
    /// @dev Update and replace loaded bytecode.
    /// @param _data The new bytecode data.
    function setBytecode(bytes _data) external onlyOwner lockAfter(2 weeks) ifNotLocked{
        require(initialized == true,", factory not initialized.");
        require(_data.length >= 32, ", incorrect bytecode size.");
        bytecode = _data;
        emit BytecodeChanged(owner, ", the owner updated the code.");
    }

    /// @dev Manual lock for contract bytecode updates.
    function lockFactory() external onlyOwner ifNotLocked{
        require(registry != address(0) && initialized == true,", registry not set.");
        locked = true;
        emit ContractLocked(owner, ", contract is locked.");
    }

    /// @dev Creates a new contract instance and calls the encoded data after creation.
    /// @dev Initialize the contract instance and creates a new entry in the contract registry.
    /// @param _data encoded data to call a specific function in the new instance.
    function createAndCall(bytes _data) external payable {
        require(initialized == true,", factory not initialized.");
        address deployed = _deployCode(bytecode);
        require(deployed.call(CONTRACT_INIT_FSIG, abi.encode(registry)));
        /* solium-disable-next-line security/no-call-value */
        require(deployed.call.value(msg.value)(_data),", failed to send data.");
        emit ContractDeployed(msg.sender, deployed);
    }

    /*
    PUBLIC FUNCTIONS
    */
    /// @dev Fallback function
    function () public {
        revert();
    }

    /*
    INTERNAL FUNCTIONS
    */
    /// @dev Function that deploys a new contract/instance.
    /// @param _data bytecode that will be deployed.
    function _deployCode(bytes memory _data) internal returns (address deployedAddress) {
        require(_data.length >= 32, ", incorrect bytecode size.");
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            deployedAddress := create(0, add(_data, 0x20), mload(_data))
            if eq(deployedAddress, 0x0) {
                revert(0, 0)
            }
        }
    }
}
