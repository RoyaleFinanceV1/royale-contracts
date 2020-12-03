// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import './RoyaleLPstorage.sol';

abstract contract curvePool is RoyaleLPstorage {
    function calc_token_amount(
        uint256[N_COINS] calldata, 
        bool
    ) virtual external view returns(uint256);

    function add_liquidity(
        uint256[N_COINS] calldata,
        uint256
    ) virtual external;

    function remove_liquidity(
        uint256,
        uint256[N_COINS] calldata
    ) virtual external;

    function remove_liquidity_imbalance(
        uint256[N_COINS] calldata,
        uint256
    ) virtual external;
}