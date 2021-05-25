// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;


interface rStrategy {

    function deposit(uint256[4] calldata) external;
    function withdraw(uint256[4] calldata,uint[4] calldata) external;
    function withdrawAll()  external returns(uint256[4] memory);
    
}
