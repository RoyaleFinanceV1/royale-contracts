// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import '../../Interfaces/IERC20Interface.sol';
import '../../Interfaces/CurveStrategyInterface.sol';

contract RoyaleLPstorage{
    
 
    
    uint256 public constant DENOMINATOR = 10000;

    uint128 public fees = 25; // for .25% fee, for 1.75% fee => 175

    uint256 public poolPart = 750 ; // 7.5% of total Liquidity will remain in the pool

    uint256 public selfBalance;

    IERC20[3] public tokens;

    IERC20 public rpToken;

    rCurveStrategy public curveStrategy;
    
    address public wallet;

    uint public YieldPoolBalance;
    uint public liquidityProvidersAPY;

    //storage for user related to supply and withdraw
    
    uint256 public lock_period = 1 minutes;

    struct depositDetails {
        uint index;
        uint amount;
        uint256 time;
        uint256 remAmt;
    }
    
    mapping(address => depositDetails[]) public amountSupplied;
    mapping(address => uint256[3]) public amountWithdraw;
    mapping(address => uint256[3]) public amountBurnt;
    
    
    mapping(address => bool) public isInQ;
    
    address[] public withdrawRecipients;
    
    uint256[3] public totalWithdraw;
    
    uint[3] public reserveAmount;
    mapping(address => bool)public reserveRecipients;
    
    
    
    //storage to store total loan given
    uint256[3] public loanGiven;  
    
    //storage realated to loan contract
     address public loanContract;
}