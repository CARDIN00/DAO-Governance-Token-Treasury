// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// The Treasury contract will serve as the DAO's fund manager. 
// This contract:
// 1:Safeguards funds deposited into it.
// 2:Executes transfers only when authorized by the DAO governance mechanism.

contract Treasury{
    address public governanceToken;

    event fundDeposites(address indexed sender, uint amount);
    event fundWithdrawn(address indexed to, uint amount);
    event fundsAllocated(address indexed to, uint amount);
    event ActionExicuted(address indexed target, uint value, bytes data);

    constructor(address _governanceContract){
        governanceToken =_governanceContract;
    }

    modifier  onlyGovernance(){
        require(msg.sender == governanceToken,"Not Authorized");
        _;
    }

    // FUNCTIONS

    function getBalance()external  view returns (uint){
        return address(this).balance;
    }

    function deposite()external payable {
        emit fundDeposites(msg.sender, msg.value);
    }

    function withdraw(address payable to, uint amount)external onlyGovernance {
        require(address(this).balance >= amount);
        to.transfer(amount);
        emit fundWithdrawn(to, amount);
    }

    function allocateFunds(address _to, uint amount)external onlyGovernance{
        require(address(this).balance >amount,"insufficient balance");
        payable(_to).transfer(amount);
        emit fundsAllocated(_to, amount);
    }

    function exicuteActions(address target, uint _value, bytes memory data)external onlyGovernance returns (bool){
        // target: This is the address of the contract or EOA you're calling.
        //  It’s passed as a parameter to the exicuteActions function
        
        // .call: The call function is a low-level way to make a function call to another contract or EOA.
        // It's often used when interacting with a contract where you might not know the exact function signature beforehand, 
        // or when performing operations like sending ether to an address
        
        // {value : _value}: This specifies how much Ether (in Wei) you want to send with the transaction.
        // _value is a parameter that represents the amount of Ether to send with the call.

        // (data): The data parameter contains the function signature and arguments (encoded in ABI format) that you want to pass to the target contract.
        // This is how you execute a specific function on the target contract.
        
        (bool success,) = target.call{value : _value}(data);
        require(success,"Action exicution failed");

        emit ActionExicuted(target, _value, data);
        return success;
        
    }
}