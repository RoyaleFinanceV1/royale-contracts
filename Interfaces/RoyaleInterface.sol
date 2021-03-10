// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface RoyaleInterface {
    function _loanWithdraw(uint256[3] memory ,uint256[3] memory,address )   external returns(bool);
    function _loanRepayment(uint256[3] memory )  external returns(bool);
    function calculateTotalToken(bool)  external view returns(uint);
    function reserveAmount(uint) external view returns(uint);
}