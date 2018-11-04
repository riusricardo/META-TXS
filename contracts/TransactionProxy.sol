pragma solidity 0.4.24;

import "./libraries/openzeppelin/migrations/Initializable.sol";
import "./libraries/openzeppelin/ECRecovery.sol";

contract TransactionProxy is Initializable {

    using ECRecovery for bytes32;

    /*
     STATE VARIABLES
    */
    address ethrReg;
    mapping(address => uint) public nonce;
    
    /*
    EXTERNAL FUNCTIONS
    */
    function initialize(address _ethrReg) external isInitializer {
        ethrReg = _ethrReg;
    }

    /*
     EVENTS
    */
    event Forwarded (
        bytes sig, 
        address signer, 
        address destination, 
        uint value, 
        bytes data,
        address rewardToken, 
        uint rewardAmount,
        bytes32 hash
    );

    /*
     PUBLIC FUNCTIONS
    */
    /// @dev Fallback function
    function () external payable{}

    function forward(
        bytes sig, 
        address signer, 
        address destination, 
        uint value, 
        bytes data, 
        address rewardToken, 
        uint rewardAmount
        ) public {

        uint seq = nonce[signer];
        bytes32 hash = keccak256(abi.encodePacked(address(this), signer, destination, value, data, rewardToken, rewardAmount, seq));
        nonce[signer]++;
        address sigAddr = ECRecovery.recover(hash.toEthSignedMessageHash(),sig);
        require(isValidDelegate(msg.sender, "veriKey", sigAddr, ethrReg),", invalid signer.");
        if(rewardAmount > 0){
            if(rewardToken == address(0)){
                msg.sender.transfer(rewardAmount);
            }else{
                require(transferToken(rewardToken,msg.sender,rewardAmount),"Could not pay with token");
            }
        }
        /* solium-disable-next-line security/no-call-value */
        require(destination.call.value(value)(data),", failed to send data."); // Cannot receive data.
        emit Forwarded(sig, signer, destination, value, data, rewardToken, rewardAmount, hash);
    }

    /*
     INTERNAL FUNCTIONS
    */
    /// @dev Gets Id Owner from the Ethr DID registry.
    /// @param _identity The address owner.
    /// @param _registry The address of the Ethr DID registry.
    function getIdOwner(
        address _identity, 
        address _registry
    ) internal view returns(address result){
        require(_registry != address(0), ", ethr registry not set.");
        require(_identity != address(0), ", invalid identity.");
        bytes memory data = abi.encodeWithSignature("identityOwner(address)", _identity);
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            let ptr := mload(0x40)
            let idOwner := staticcall(sub(gas, 1500), _registry, add(data, 0x20), mload(data), ptr, 0x20)
            if eq(idOwner, 0x0) {
                revert(0, 0)
            }
            result := mload(ptr)
        } 
    }

    /// @dev Verifies if the signer delegate is valid in the Ethr DID registry.
    /// @param _identity The address owner.
    /// @param _delegateType Type of delegate. Signer -> Secp256k1VerificationKey2018 -> bytes32("veriKey").
    /// @param _delegate The address of the signer delegate.
    /// @param _registry The address of the Ethr DID registry.
    function isValidDelegate(
        address _identity, 
        string _delegateType, 
        address _delegate, 
        address _registry
    ) internal view returns(bool result){
        require(_registry != address(0), ", ethr registry not set.");
        require(_identity != address(0) && bytes(_delegateType).length > 0 && _delegate != address(0),", invalid delegate input.");
        bytes memory data = abi.encodeWithSignature("validDelegate(address,bytes32,address)", _identity, stringToBytes32(_delegateType), _delegate);
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            let ptr := mload(0x40)
            let success := staticcall(sub(gas, 3800), _registry, add(data, 0x20), mload(data), ptr, 0x20)
            if eq(success, 0) {
                revert(0, 0)
            }
            result := mload(ptr)
        } 
    } 

    // @title SecuredTokenTransfer - Secure token transfer
    // @author Richard Meissner - <richard@gnosis.pm>
    /// @dev Transfers a token and returns if it was a success
    /// @param token Token that should be transferred
    /// @param receiver Receiver to whom the token should be transferred
    /// @param amount The amount of tokens that should be transferred
    function transferToken (
        address token, 
        address receiver,
        uint256 amount
    )
        internal
        returns (bool transferred)
    {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", receiver, amount);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let success := call(sub(gas, 10000), token, 0, add(data, 0x20), mload(data), 0, 0)
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize)
            switch returndatasize 
            case 0 { transferred := success }
            case 0x20 { transferred := iszero(or(iszero(success), iszero(mload(ptr)))) }
            default { transferred := 0 }
        }
    }

    /// @dev Converts string to bytes32 type.
    /// @param _string string data.
    /// @return string converted to bytes32.
    function stringToBytes32(string memory _string) internal pure returns (bytes32) {
        bytes32 result;
        require(bytes(_string).length > 0, ", incorrect string lenght.");
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            result := mload(add(_string, 32))
        }
        return result;
    }  
}
