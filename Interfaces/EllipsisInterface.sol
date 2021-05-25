// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;


interface EllipsisDAIPool{
    
    function get_virtual_price() external view returns(uint256);
    
    function calc_token_amount(uint256[2] memory, bool)  external view returns(uint256);
}

interface Ellipsis3Pool{
    
     function get_virtual_price() external view returns(uint256);
    
     function calc_token_amount(uint256[3] memory, bool)  external view returns(uint256);
}


interface DepositZap{
    
    function add_liquidity(uint256[4] memory, uint256) external returns(uint256);
    
    function remove_liquidity(uint256,uint256[4] memory) external returns(uint256[4] memory);
    
    function remove_liquidity_one_coin(uint256,int128,uint256) external returns(uint256);
    
    function remove_liquidity_imbalance(uint256[4] memory,uint256) external returns(uint256);
    
    function calc_token_amount(uint256[4] memory, bool) external returns(uint256);
    
}

interface LPStaker{
     function deposit(uint256 _pid, uint256 _amount) external;
     function withdraw(uint256 _pid, uint256 _amount) external;
     function emergencyWithdraw(uint256 _pid) external;
     function claimableReward(uint256 _pid, address _user)external view returns (uint256);
     function claim(uint256[] memory _pids) external;
     function userInfo(uint , address) external view returns(uint,uint);
}


interface EPSStaker{
    function stake(uint256 amount, bool lock) external;
    function withdraw(uint256 amount) external ;
    function getReward() external;
    function exit() external ;
    function withdrawExpiredLocks() external;
    function withdrawableBalance(address user) view external returns ( uint256 amount,uint256 penaltyAmount);
    function unlockedBalance(address user) view external returns (uint256 amount);
}