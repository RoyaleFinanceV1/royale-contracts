// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface aavePool{
    function get_virtual_price() external returns(uint256);
    function calc_token_amount(uint256[3] memory,bool) external returns(uint256);
    function add_liquidity(uint256[3] memory,uint256,bool) external returns(uint256);
    function remove_liquidity(uint256,uint256[3] memory,bool) external returns (uint256[3] memory);
    function remove_liquidity_imbalance(uint256[3] memory,uint256,bool) external returns(uint256);
}

interface aaveGauge{
    function deposit(uint256) external;
    function withdraw( uint256) external;
    function balanceOf(address) external returns(uint256);
    function claim_rewards() external;
    function claim_historic_rewards(address[8] memory) external;
}