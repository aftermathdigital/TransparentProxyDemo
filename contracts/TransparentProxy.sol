//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;
contract TransparentProxy {
    struct Voter {
        uint weight;
        bool voted;
        uint8 vote;
    }
    struct Proposal {
        uint voteCount;
    }
    enum Stage {Init,Reg, Vote, Done}
    
    //Variables, defined in exactly the same way as in the logic contract.
    Stage public stage = Stage.Init;
    address chairperson;
    mapping(address => Voter) voters;
    Proposal[] proposals;
    Voter sender;
    uint startTime;
    //End variables

    //Constants don't use storage slots
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    struct _addressSlot {
        address value;
    }
    
    //isOwner modifier, prevents anyone other than owner from upgrading contract implementation
    modifier isOwner() {
        require(msg.sender == getAddressSlot(_ADMIN_SLOT).value);
        _;
    }
 
    //Constructor, sets admin slot to msg.sender
    constructor(address _implementation){
        getAddressSlot(_ADMIN_SLOT).value = msg.sender;
        upgradeLogic(_implementation);
    }
    
    //get an address from a slot
    function getAddressSlot(bytes32 slot) internal pure returns (_addressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
    
    //overwrite the implementation slot, isOwner only.
    function upgradeLogic(address _newImplementation) isOwner public {
        getAddressSlot(_IMPLEMENTATION_SLOT).value = _newImplementation;
    }
    
    fallback() external {
        address implementation = getAddressSlot(_IMPLEMENTATION_SLOT).value;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}