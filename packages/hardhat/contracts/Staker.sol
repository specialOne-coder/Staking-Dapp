pragma solidity >=0.6.0 <0.7.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint256) public balances; // balance of user staked fund

  uint256 public constant threshold = 1 ether; // staking threshold

  uint256 public deadline = block.timestamp + 30 seconds;
  
  event StakeEvent(address indexed sender,uint256 amount);  //stake event

  // modifier that require to be reached or not
  modifier deadlineReached(bool requireReached){
    uint256 timeRemaining = timeLeft();
    if(requireReached){
      require(timeRemaining == 0,"Deadline is not reached yet");
    }else{
      require(timeRemaining > 0,"Deadline is already reached");
    }
    _;
  }

  //modifier that require to external contract to not be completed.
  modifier notCompleted(){
    bool completed = exampleExternalContract.completed();
    require(!completed,"External contract is already completed");
    _;
  }


  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable deadlineReached(false) notCompleted{
    balances[msg.sender] += msg.value;
    emit StakeEvent(msg.sender, msg.value);  
  }


  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public payable deadlineReached(false) notCompleted{
    uint256 contractBalance = address(this).balance;
    require(contractBalance >= threshold,"Contract balance is not enough to complete");
    (bool sent,) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature( "complete()"));
    require(sent,"Could not send value to external contract");
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() public deadlineReached(true) notCompleted{
    uint256 balance = balances[msg.sender];
    require(balance > 0,"No funds to withdraw");
    balances[msg.sender] = 0;
    (bool sent,) = msg.sender.call{value: balance}("");
    exampleExternalContract.complete{value: balances[msg.sender]};
    require(sent,"Could not send funds to external contract");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint256){
    if(block.timestamp > deadline){
      return 0;
    }else{
      return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()


}
