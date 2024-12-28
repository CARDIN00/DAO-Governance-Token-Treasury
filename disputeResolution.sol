// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract disputeResolution{

    address public  Admin;

    constructor(){
        Admin = msg.sender;
    }

    struct disputes{
        uint proposalId;
        string reason;
        address proposer; // who raised the dispute
        bool resolved;
        bool outcome;
    }
    mapping (address => bool) public arbitrators;
    mapping (uint => disputes)public Disputes;

    event DisputeCreated(uint proposalId, address proposer, string reason);
    event DisputeResolved(uint proposalId, bool outcome);

    modifier onlyAdmin(){
        require(msg.sender == Admin,"Only Admin");
        _;
    }

    modifier onlyArbitrator(){
        require(arbitrators[msg.sender],"Not anarbitrator");
        _;
    }

    // Functions
    function addArbitrator(address _new)external  onlyAdmin{
        arbitrators[_new] = true;
    }

    function removeArbitrator(address _arbitrator) external  onlyAdmin{
        require(arbitrators[_arbitrator],"Not an arbitrator");
        arbitrators[_arbitrator] =false;
    }

    function createDispute(uint _proposalId, string memory _reason)external {
        require(bytes(_reason).length > 0,"Enter Reason");
        Disputes[_proposalId] = disputes({
            proposalId : _proposalId,
            proposer : msg.sender,
            reason : _reason,
            resolved : false,
            outcome :false
        });
        emit DisputeCreated(_proposalId, msg.sender, _reason);
    }

    function resolveDispute(uint _proposalId) external view returns (string memory, bool) {
    disputes storage dispute = Disputes[_proposalId];
    require(dispute.resolved, "Dispute not yet resolved");
    return (dispute.reason, dispute.outcome);
    }
}