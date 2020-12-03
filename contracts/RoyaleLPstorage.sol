// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import './Erc20Interface.sol';
import './CurveInterface.sol';

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

    uint128 constant N_COINS = 3;

    uint128 public fees = 25;

    uint256[N_COINS] public selfBalance;

    address public owner;
    curvePool Pool;
    Erc20[N_COINS] tokens;
    Erc20 PoolToken;
    Erc20 rpToken;

    // Lock period in days
    uint128 lock_period = 14;

    struct depositDetails {
        uint256[N_COINS] amount;
        uint256 time;
    }

    mapping(address => bool) hasSupplied;
    mapping(address => uint256[N_COINS]) amountSupplied;
    mapping(address => depositDetails[]) supplyTime;

    mapping(address => uint256[N_COINS]) amountWithdraw;
    mapping(address => bool) public isInQ;
    uint32 recipientCount;
    uint256[N_COINS] public totalWithdraw;

    /* MULTISIG STORAGE */

    uint constant public MAX_SIGNEE_COUNT = 50;
    
    mapping(address => Transaction) public transactions;
    mapping(address => mapping (address => bool)) public confirmations;
    mapping(address => mapping(uint256 => Repayment)) gamingCompanyRepayment;
    mapping(address => bool) public isSignee; // isSignee
    address[] public signees;
    uint256 public transactionCount = 0;
    uint256 public required;
    
    uint256 public counter;
    address public ownerAddress;
    
    address public royaleLPContract;

    struct Transaction {
        address gamingCompany;
        bool isGamingCompanySigned;
        uint256[N_COINS] tokenAmounts;
        uint256[N_COINS] remAmt;
        bool approved;
        bool executed;
    }

    struct Repayment {
        uint256 transactionID;
        bool isRepaymentDone;
        uint256[N_COINS] remainingTokenAmounts;
    }
}