// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

abstract contract Erc20 {
    function approve(
        address,
        uint256
    ) virtual public returns(bool);

    function balanceOf(address) virtual public view returns(uint256);

    function decimals() virtual public view returns(uint8);

    function totalSupply() virtual public view returns(uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) virtual public returns(bool);

    function transfer(
        address,
        uint256
    ) virtual public returns(bool);

    function mint(address recipient, uint256 amount) virtual public;
    function burn(address recipient, uint256 amount) virtual public;
}