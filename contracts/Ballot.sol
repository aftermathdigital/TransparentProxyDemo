//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;
contract Ballot {
    struct Voter {
        uint weight;
        bool voted;
        uint8 vote;
        //address delegate;
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

    event votingCompleted();
    
    //modifiers
    modifier validStage(Stage reqStage)
    { require(stage == reqStage, "Wrong stage");
      _;
    }

    modifier onlyBy(address _account)
    {
        require(msg.sender == _account, "Only chairperson can register voters");
        _;
    }

    /// Create a new ballot with $(_numProposals) different proposals.
    constructor() {
    }

    /// Create a new ballot with $(_numProposals) different proposals.
    function initialize(uint8 _numProposals) public {
        require(chairperson == address(0x0), "Cannot re-initialize contract"); //prevent re-initialization
        chairperson = msg.sender;
        voters[chairperson].weight = 2;
        for(uint i = 0; i < _numProposals; i++){
            //new syntax since length is not writable
            proposals.push();
        }
        stage = Stage.Reg;
        startTime = block.timestamp;
    }
    /// Give $(toVoter) the right to vote on this ballot.
    /// May only be called by $(chairperson).
    function register(address toVoter) public validStage(Stage.Reg) onlyBy(chairperson) {
        if (msg.sender != chairperson || voters[toVoter].voted) return;
        voters[toVoter].weight = 1;
        voters[toVoter].voted = false;
        if (block.timestamp > (startTime+ 30 seconds)) {
            stage = Stage.Vote;
            startTime = block.timestamp;
        }        
    }
    /// Give a single vote to proposal $(toProposal).
    function vote(uint8 toProposal) public validStage(Stage.Vote)  {
        sender = voters[msg.sender];
        require(!sender.voted, "Can't vote twice");
        require(toProposal < proposals.length, "Can't vote twice");
        require(sender.weight > 0, "Only registered voters can vote");
        sender.voted = true;
        sender.vote = toProposal;   
        proposals[toProposal].voteCount += sender.weight;
        if (block.timestamp > (startTime+ 30 seconds)) {
            stage = Stage.Done;
            startTime = block.timestamp;
            emit votingCompleted();
        }        
        
    }

    function winningProposal() public validStage(Stage.Done) view returns (uint8 _winningProposal) {
        uint256 winningVoteCount = 0;
        for (uint8 prop = 0; prop < proposals.length; prop++) {
            if (proposals[prop].voteCount > winningVoteCount) {
                winningVoteCount = proposals[prop].voteCount;
                _winningProposal = prop;
            }
	}
       assert (winningVoteCount > 0);
    }
}
