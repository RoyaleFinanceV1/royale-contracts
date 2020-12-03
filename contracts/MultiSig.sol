// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './Erc20Interface.sol';
import './RoyaleLPstorage.sol';

contract multiSig is RoyaleLPstorage {

    /* Modifiers */

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier signeeDoesNotExist(address signee) {
        require(!isSignee[signee]);
        _;
    }

    modifier signeeExists(address signee) {
        require(isSignee[signee]);
        _;
    }

    modifier transactionExists(address addr) {
        require(transactions[addr].gamingCompany != address(0));
        _;
    }

    modifier confirmed(address addr, address signee) {
        require(confirmations[addr][signee]);
        _;
    }

    modifier notConfirmed(address addr, address signee) {
        require(!confirmations[addr][signee]);
        _;
    }

    modifier notExecuted(address addr) {
        require(!transactions[addr].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address !=address(0));
        _;
    }

    modifier validRequirement(uint signeeCount, uint _required) {
        require(signeeCount <= MAX_SIGNEE_COUNT
            && _required <= signeeCount
            && _required != 0
            && signeeCount != 0);
        _;
    }

    /* Internal Functions */

    function _addTransaction(
       uint256[N_COINS] memory amounts
    ) internal {
        uint256[N_COINS] memory zero;
        transactions[msg.sender] = Transaction({
            gamingCompany: msg.sender,
            tokenAmounts: amounts,
            remAmt: zero,
            isGamingCompanySigned: false,
            approved: false,
            executed: false
        });
        
        transactionCount += 1;
    }

    function _approveLoan(address addr) internal {
        transactions[addr].approved = true;
        transactions[addr].remAmt = transactions[addr].tokenAmounts;
    }
    
    function _isConfirmed(
        address addr
    ) internal view returns (bool) {
        uint count = 0;
        for (uint i=0; i<signees.length; i++) {
            if (confirmations[addr][signees[i]])
                count += 1;
            if (count == required && transactions[addr].isGamingCompanySigned)
                return true;
        }
    }

    /* USER FUNCTIONS (exposed to frontend) */

    // Gaming platforms withdraw using this
    function requestLoan(
        uint256[N_COINS] calldata amounts
    ) external {
       require(signees.length >= required, "signees are less than required");
       _addTransaction(amounts);
    }
    
    // Gaming Platforms signs using this
    function signTransaction() public {
        require(transactions[msg.sender].gamingCompany == msg.sender);
        transactions[msg.sender].isGamingCompanySigned = true;
    }
    
    // Signee signs using this
    function confirmLoan(address addr) public
        signeeExists(msg.sender)
        transactionExists(addr)
        notConfirmed(addr, msg.sender) 
    {
        confirmations[addr][msg.sender] = true;

        if(_isConfirmed(addr)) {
           _approveLoan(addr);
        }
    }
    
    function checkLoanApproved(address addr) public view returns(bool) {
        return transactions[addr].approved;
    }

    function getTransactionDetail(
        address addr
    ) public view returns(Transaction memory){
        return transactions[addr];
    }

    /* Admin Function */
    
    function setRequiredSignee(
        uint _required
    ) public validRequirement(signees.length, _required) {
        required = _required;
    }

    function addSignee(address signee) public onlyOwner {
        isSignee[signee] = true;
        signees.push(signee);
    }
    
    function removeSignee(address signee) public signeeExists(signee) {
        isSignee[signee] = false;
        for (uint i=0; i<signees.length - 1; i++)
            if (signees[i] == signee) {
                signees[i] = signees[signees.length - 1];
                break;
            }
        
        if (required > signees.length)
            setRequiredSignee(signees.length);
    }
}