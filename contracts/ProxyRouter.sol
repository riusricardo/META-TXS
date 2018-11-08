pragma solidity ^0.4.24;

import "./libraries/openzeppelin/migrations/Initializable.sol";
import "./libraries/openzeppelin/upgradeability/Proxy.sol";
import "./libraries/openzeppelin/utils/Address.sol";

contract ProxyRouter is Proxy,Initializable{
    /*
     POINTERS SIGNATURES
    */
    bytes4 private constant CONTRACT_INIT_SIG = bytes4(keccak256("initialize(address)"));

    /*
     STATE VARIABLES
    */
    address internal implementation = address(0);
    address public registry = address(0);
    address public owner = address(0);

    struct Route {
        mapping(bytes4 => address) contractPointers;
        mapping(bytes4 => bool) allowedPointers;
    }

    /*
    EXTERNAL FUNCTIONS
    */
    function initialize(address _registry,address _owner,address _implementation) external isInitializer {
        require(registry == address(0) && owner == address(0),", already set.");
        require(Address.isContract(_registry), ", cannot set a proxy implementation to a non-contract address");
        implementation = _implementation;
        registry = _registry;
        owner = _owner;
    }

    /*
     INTERNAL FUNCTIONS
    */
    /// @dev Returns the current implementation.
    /// @return Address of the current implementation
    function _implementation() internal view returns (address) {
        if(msg.sender == owner){
            return implementation;
        } else {
            return registry;
        }
    }

    /// @dev Function that is run as the first thing in the fallback function.
    function _willFallback() internal {
        super._willFallback();
    }
}
