// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import '../../Interfaces/IERC20Interface.sol';
import '../../Interfaces/CurveStrategyInterface.sol';

contract WithdrawQueue {
    mapping(uint256 => address) withdrawQ;
    uint256 first = 1;
    uint256 last = 0;
    address data;

    function addToQ(address addr) internal {
        last += 1;
        withdrawQ[last] = addr;
    }

    function getFromQ() internal returns(address) {
        require(last >= first);

        data = withdrawQ[first];

        delete withdrawQ[first];
        first += 1;

        return data;
    }
    
}


contract RoyaleLPstorage  is WithdrawQueue {
    
    //storage for pool features
    
    uint256 public constant DENOMINATOR = 10000;

    uint128 public fees = 25; // for .25% fee, for 1.75% fee => 175

    uint256 public poolPart = 750 ; // 7.5% of total Liquidity will remain in the pool

    uint256[3] public selfBalance;

    IERC20[3] tokens;

    IERC20 rpToken;

    rCurveStrategy curveStrategy;
    
    address public wallet;

    uint[3] public YieldPoolBalance;
    uint[3] public liquidityProvidersAPY;

    uint256 public threshold = 500;
    //storage for user related to supply and withdraw
    uint256 public lock_period = 1 minutes;

    struct depositDetails {
        uint256 index;
        uint256 amount;
        uint256 time;
        uint256 remAmt;
        
    }
    
    mapping(address => depositDetails[]) public amountSupplied;
    mapping(address => uint256[3]) public amountWithdraw;
    mapping(address => uint256[3]) public amountBurnt;
    
    mapping(address => bool) public isInQ;
    
    uint32 recipientCount;
    
    uint256[3] public totalWithdraw;

    //storage to store total loan given
    uint256[3] public loanGiven;  
    
    //storage realated to loan contract
     address public loanContract;
}