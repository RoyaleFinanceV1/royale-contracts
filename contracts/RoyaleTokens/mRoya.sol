// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MRoya is ERC20 {

    address public wallet;
    mapping(address => bool) public minter;

    constructor(address _wallet) public ERC20("mRoya Token", "mRoya") {
        wallet = _wallet;
    }

    modifier onlyWallet {
        require(msg.sender == wallet, "not authorized");
        _;
    }

    modifier onlyMinter {
        require(minter[msg.sender] == true, "not authorized");
        _;
    }

    function transferOwnership(address _wallet)external onlyWallet{
        wallet=_wallet;
    }

    function addMinter(address addr) external onlyWallet returns(bool) {
        minter[addr] = true;
        return true;
    }

    function removeMinter(address addr) external onlyWallet returns(bool) {
        minter[addr] = false;
        return true;
    }

    function mint(address recipient, uint256 amount) external onlyMinter {
        _mint(recipient, amount);
    }

    function burn(address sender, uint256 amount) external onlyMinter {
        _burn(sender, amount);
    }
}