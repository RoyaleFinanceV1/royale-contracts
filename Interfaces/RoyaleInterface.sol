// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

abstract contract RoyaleInterface {
    function _loanWithdraw(uint256[3] calldata amounts,uint256[3] calldata withdrawAmounts,address _loanSeeker) virtual  external returns(bool);
    function _loanRepayment(uint256[3] calldata amounts,address _loanSeeker) virtual  external returns(bool);
    function selfBalance(uint) virtual external view returns(uint256);
    function reserveAmount(uint) virtual external view returns(uint);
    
    
}