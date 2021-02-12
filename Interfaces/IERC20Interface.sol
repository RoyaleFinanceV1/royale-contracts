// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface IERC20{
    function approve( address, uint256)  external returns(bool);

    function balanceOf(address)  external view returns(uint256);

    function decimals()  external view returns(uint8);

    function totalSupply() external  view returns(uint256);

    function transferFrom(address,address,uint256) external  returns(bool);

    function transfer(address,uint256) external  returns(bool);

    function mint(address , uint256 ) external ;
    function burn(address , uint256 ) external ;
    function getPricePerFullShare()  external view returns (uint256);
}