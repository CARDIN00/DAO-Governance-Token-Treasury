// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Rewarding{
    ERC20 public rewardToken;

    uint public rewardPerVote = 5* 10**18;

    constructor(address _token){
        rewardToken = ERC20(_token);
    }

    mapping (address => uint)public Reward;
    mapping (address => uint) public lastVoted;

    // Functions
    function distributeReward(address voter)external returns(uint) {
        uint rewardAmount = rewardPerVote;
        Reward[voter] += rewardAmount;
        return rewardAmount;
    }

    function claimReward()external {
        uint rewardAmount = Reward[msg.sender];
        require(rewardAmount > 0,"No rewards pending");

        Reward[msg.sender] = 0;
        rewardToken.transfer(msg.sender, rewardAmount);
    }

    function getRewardBalance(address voter)external  view returns (uint){
        return Reward[voter];
    }


}