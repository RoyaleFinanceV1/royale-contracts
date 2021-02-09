// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MRoya is ERC20 {

    address public owner;
    mapping(address => bool) public minter;

    constructor() public ERC20("mRoya Token", "mRoya") {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier onlyMinter {
        require(minter[msg.sender] == true, "not authorized");
        _;
    }

    function addMinter(address addr) external onlyOwner returns(bool) {
        minter[addr] = true;
    }

    function removeMinter(address addr) external onlyOwner returns(bool) {
        minter[addr] = false;
    }

    function mint(address recipient, uint256 amount) external onlyMinter {
        _mint(recipient, amount);
    }

    function burn(address sender, uint256 amount) external onlyMinter {
        _burn(sender, amount);
    }
}