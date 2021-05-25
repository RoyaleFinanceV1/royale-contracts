// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface Pancake{
    
    function swapExactTokensForTokens(uint256,uint256,address[] calldata,address,uint256) external;
}