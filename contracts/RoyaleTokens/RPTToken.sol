// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract RPTToken is ERC20 {
    address public minter;
    address public wallet;
    

    constructor(address _wallet) public ERC20("Royale Protocol", "RPT") {
           wallet=_wallet;
    }
    
    modifier onlyMinter {
        require(msg.sender==minter, "not authorized");
        _;
    }
    
    modifier onlyWallet(){
      require(wallet==msg.sender, "Not Authorized");
      _;
    }

    function transferOwnership(address _owner)external onlyWallet{
        wallet=_owner;
    }
    
    function setMinter(address addr) external  onlyWallet{
        minter = addr;
    }

    function mint(address recipient, uint256 amount) public onlyMinter {
        _mint(recipient, amount);
    }

    function burn(address sender, uint256 amount) external onlyMinter {
        _burn(sender, amount);
    }
}