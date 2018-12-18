pragma solidity 0.4.24;

import "./libraries/openzeppelin/migrations/Initializable.sol";
import "./libraries/openzeppelin/utils/Address.sol";

contract ProxyRouter is Initializable{
    /*
     POINTERS SIGNATURES
    */
    bytes4 private constant OTHER_ROUTE = bytes4(keccak256("Other.Test"));
    bytes4 private constant DATA_ROUTE = bytes4(keccak256("Data.Send"));

    /*
     STATE VARIABLES
    */
    address public fallbackAddr = address(0);
    mapping(bytes4 => address) public  contractPointer;
    mapping(bytes4 => bool) public allowedPointer;

    /*
    EXTERNAL FUNCTIONS
    */
    function initialize(
        address _fallback
    ) 
        external 
        isInitializer 
    {
        require(fallbackAddr == address(0),", already set.");
        require(Address.isContract(_fallback), ", cannot set a proxy implementation to a non-contract address");
        fallbackAddr = _fallback;
        allowedPointer[TOKEN_ROUTE] = true;
        allowedPointer[DATA_ROUTE] = true;
    }

    function () external payable {
        _fallback();
    }

    /*
     INTERNAL FUNCTIONS
    */
    function _decodeData() 
        internal 
        view 
        returns (
            address relay,
            address destination, 
            bytes memory data, 
            uint size
        ) 
    {
        if(allowedPointer[msg.sig]){
            relay = contractPointer[msg.sig];
            /* solium-disable-next-line security/no-inline-assembly */
            assembly {
                size := sub(calldatasize,0x24) // substract 36 bytes.
                calldatacopy(destination, 0x04, 0x20)
                calldatacopy(data, 0x24, size)
            }
        } else {
            relay = address(0);
            destination = fallbackAddr;
            data = msg.data;
            size = msg.data.length;
        }
    }

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param _destination Address to delegate.
   */
    function _delegate(
        address _relay,
        address _destination, 
        bytes memory _data, 
        uint _size
    ) 
        internal 
    {
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas, _destination, _data, _size, 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize)

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
    function _fallback() internal {
        (address relay,address destination,bytes memory data,uint size) = _decodeData();
        _delegate(relay, destination, data, size);
    }
}
