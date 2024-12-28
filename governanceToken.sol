// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./disputeResolution.sol"; 
contract GovernanceToken is ERC20{

    uint public proposalCount;
    uint public votingPeriod = 7 days;
    uint public tokenHolderCount;

    uint public quorumThreshold = 30; // Example: 30% of the total token supply must vote
    uint executionDelay = 3 days;

    //dispute resolution contract
    disputeResolution public disputeResolutionContract;


    constructor(uint initialSupply,address _disputeResolutionContract) ERC20("GovernanceToken","GOV"){
        _mint(msg.sender, initialSupply);
        disputeResolutionContract = disputeResolution(_disputeResolutionContract);
        
    }

    struct proposal{
        uint id;
        string description;
        uint voteCountFor;
        uint voteCountAgainst;
        uint endTime;
        bool exicuted;
        address proposer;
        bool active;
        address[] target; // Address to execute the proposal action
        bytes[] data;     // Encoded function call for execution
        uint totalVotes;
    }

    mapping (uint => proposal)public Proposals;
    //vote by each address for each proposal
    mapping (address => mapping (uint =>bool))public votes;
    //track all the token holders
    mapping (address => bool)public TokenHolder;

    // EVENTS
    event proposalCreated(address indexed creator, string indexed description);
    event voted(address indexed voter, uint proposalId, bool vote);
    event proposalExicution(uint proposalId, bool exicuted);
    event CancleProposal(uint prosalId, address indexed proposer);
    event modiedProposals(uint indexed  proposalId, string newDescription);
    event DisputeCreated(uint proposalId, address proposer, string reason);
    event DisputeResolved(uint proposalId, bool outcome);

    // FUNCTIONS
    function createProposal(
        string memory _description,
        bytes[] memory _data,
        address[] memory _targets
        )
        external
        {

        require(_targets.length == _data.length, "Mismatched targets and data lengths");    
        uint proposalId = proposalCount++;
        uint _endTime =block.timestamp + votingPeriod;

        Proposals[proposalId] = proposal({
            id : proposalId,
            description : _description,
            voteCountFor : 0,
            voteCountAgainst : 0,
            endTime : _endTime,
            exicuted :false,
            proposer :msg.sender,
            active : true,
            target :_targets,
            data : _data,
            totalVotes : 0
        });

        emit proposalCreated(msg.sender, _description);
    }

    // vote for a proposal
    function vote(uint proposalId, bool support)external{
        require(Proposals[proposalId].active,"Voting time over");
        require(block.timestamp < Proposals[proposalId].endTime);
        require(votes[msg.sender][proposalId] == false,"Already voted");

        if(support){
            Proposals[proposalId].voteCountFor++;
        }
        else{
            Proposals[proposalId].voteCountAgainst++;
        }

        Proposals[proposalId].totalVotes++;

        votes[msg.sender][proposalId] = true;
        emit  voted(msg.sender, proposalId, support);
    }

    function exicuteProposalAction(address target, bytes memory data)internal returns (bool){
        // Execute the proposal's action on the target address
        (bool success, ) = target.call(data);
        return success;
    }

    // Finalize the proposal
    function finalizeProposal(uint proposalId)external{
        proposal storage prop = Proposals[proposalId];
        require(Proposals[proposalId].active ,"Already Finalized");
        require(block.timestamp >= Proposals[proposalId].endTime);
        require(prop.exicuted == false,"Already finalized");

        (string memory dispureReason, bool disputeOutcome) =disputeResolutionContract.resolveDispute(proposalId);

        if(!disputeOutcome){
            revert(string(abi.encodePacked("Porposal exicution halted :", dispureReason))) ;
        }

        uint quorumVotes =(totalSupply() * quorumThreshold)/100;
        require(prop.totalVotes >quorumVotes,"not enough votes");

        if(prop.voteCountAgainst < prop.voteCountFor && !prop.exicuted){
            require(block.timestamp >= executionDelay + prop.endTime,"wait time not over");
            for(uint i =0; i < prop.target.length; i++){
                bool success = exicuteProposalAction(prop.target[i], prop.data[i]);
            require(success,"Proposal exicution failed");
            }
        }

        prop.exicuted = true;
        prop.active = false;

        emit proposalExicution(proposalId, prop.exicuted);

    }

    function getVotingResults(uint proposalId) external view returns (string memory description, uint voteCountFor,uint voteCountAgainst){
        proposal memory prop = Proposals[proposalId];
        return (prop.description, prop.voteCountFor, prop.voteCountAgainst);
    }

    function cancleProposal(uint _proposalId)external  {
        proposal storage prop = Proposals[_proposalId];
        require(prop.active == true,"Not Active anymore");
        require(msg.sender == prop.proposer,"Only proposer my cancel");
        require(block.timestamp < prop.endTime,"voting time already over");

        prop.active = false;
        emit CancleProposal(_proposalId, prop.proposer);

    }

     function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _updateHolderStatus(msg.sender, recipient, amount);
        return super.transfer(recipient, amount);
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _updateHolderStatus(sender, recipient, amount);
        return super.transferFrom(sender, recipient, amount);
    }

    // update the holder mapping and count
    function _updateHolderStatus(address sender, address recipient, uint256 amount) internal {
        if (balanceOf(recipient) == 0 && amount > 0) {
            TokenHolder[recipient] = true;
            tokenHolderCount++;
        }

        if (balanceOf(sender) - amount == 0) {
            TokenHolder[sender] = false;
            tokenHolderCount--;
        }
    }

    // if an address is a token holder
    function isHolder(address account) external view returns (bool) {
        return TokenHolder[account];
    }

    function modiFyProposal(uint _proposalId, string memory _description, bytes[] memory newData, address[] memory newTarget) external {
        proposal storage prop = Proposals[_proposalId];

        require(newData.length == newData.length,"Mismatch in data-target lengths");
        
        require(msg.sender == prop.proposer,"Only proposer may modyfy");
        require(prop.active == true,"Not Active anymore");
        require(block.timestamp < prop.endTime,"voting time already over");

        for(uint i=0; i<newTarget.length; i++){
            require(newTarget[i] != address(0),"Invalid target address");
        }

        prop.description = _description;
        prop.data = newData;
        prop.target = newTarget;
        

        emit modiedProposals(_proposalId, _description);
    }

    // DISPUTE FUNCTIONS
    function createDispute(uint _proposalId, string memory _reason)external {
        require(bytes(_reason).length > 0,"Enter Reason");
        disputeResolutionContract.createDispute(_proposalId, _reason);
    }


}
