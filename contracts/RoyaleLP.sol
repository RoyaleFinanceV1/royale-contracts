// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './MathLib.sol';

import './Erc20Interface.sol';
import './CurveInterface.sol';
import './RoyaleLPstorage.sol';
import './MultiSig.sol';

contract RoyaleLP is RoyaleLPstorage, multiSig, BNum {

    constructor(
        address _pool, 
        address[N_COINS] memory _tokens,
        address _poolToken,
        address _rpToken
    ) public {
        // Set Curve Pool
        Pool = curvePool(_pool);

        // Set Tokens supported by Curve Pool
        for(uint8 i=0; i<N_COINS; i++) {
            tokens[i] = Erc20(_tokens[i]);
        }

        // Set pool Token
        PoolToken = Erc20(_poolToken);

        // Set RPT
        rpToken = Erc20(_rpToken);

        // Set owner
        owner = msg.sender;
    }
    
    /* INTERNAL FUNCTIONS */

    function _getBalances() internal view returns(uint256[N_COINS] memory) {
        uint256[N_COINS] memory balances;

        for(uint8 i=0; i<N_COINS; i++) {
            balances[i] = tokens[i].balanceOf(address(this));
        }

        return balances;
    }

    function _calcRptAmount(uint256[N_COINS] memory amounts, bool burn) internal view returns(uint256) {
        uint256 rptAmt;
        uint256 total = 0;
        uint256 decimal = 0;
        uint256 totalSuppliedTokens;
        uint256 totalRPTSupply;

        totalRPTSupply = bdiv(rpToken.totalSupply(), 10**18);
        
        for(uint8 i=0; i<N_COINS; i++) {
            decimal = tokens[i].decimals();
            total += bdiv(selfBalance[i], 10**decimal);
            totalSuppliedTokens += bdiv(amounts[i], 10**decimal);
        }

        rptAmt = bmul(bdiv(totalSuppliedTokens, total), totalRPTSupply);

        if(burn == true) {
            rptAmt = rptAmt + (rptAmt * fees) / 10000;
        }

        return rptAmt;
    }

    // functions related to deposit and supply

    // This function deposits the fund to 3POOL
    function _deposit(uint256[N_COINS] memory amounts) internal {
        uint mintAmount = Pool.calc_token_amount(amounts, true);
        mintAmount = (99 * mintAmount) / 100;
        Pool.add_liquidity(amounts, mintAmount);
    }

    function _supply(uint256[N_COINS] memory amounts) internal {
        uint256 mintTokens;        
        mintTokens = _calcRptAmount(amounts, false);    
        
        bool result;
        for(uint8 i=0; i<N_COINS; i++) {
            if(amounts[i] > 0) {
                result = tokens[i].transferFrom(
                    msg.sender, 
                    address(this), 
                    amounts[i]
                );
                require(result);
                selfBalance[i] += amounts[i];
                amountSupplied[msg.sender][i] += amounts[i];
            }
        }
    
        // rpToken.mint(msg.sender, mintTokens * 10**10);
        rpToken.mint(msg.sender, mintTokens);

        depositDetails memory d = depositDetails(amounts, now);
        supplyTime[msg.sender].push(d);
    }

    // functions related to withdraw, withdraw queue and withdraw from curve pool

    function _takeBack(address recipient) internal {
        bool result;

        uint256 burnAmt;

        burnAmt = _calcRptAmount(amountWithdraw[recipient], true);
        rpToken.burn(recipient, burnAmt);

        for(uint8 i=0; i<N_COINS; i++) {
            if(
                amountWithdraw[recipient][i] > 0 
                && 
                amountSupplied[recipient][i] > 0
            ) {
                result = tokens[i].transfer(
                    recipient,  
                    amountWithdraw[recipient][i]
                );
                require(result);

                amountSupplied[recipient][i] -= amountWithdraw[recipient][i];
                totalWithdraw[i] -= amountWithdraw[recipient][i];
                selfBalance[i] -= amountWithdraw[recipient][i];
                amountWithdraw[recipient][i] = 0;

                isInQ[recipient] = false;
                recipientCount -= 1;
            }
        }

        for(uint8 i=0; i<supplyTime[recipient].length - 1; i++) {
            supplyTime[recipient][i] = supplyTime[recipient][i+1];
        }
        supplyTime[recipient].pop();
    }

    // this will fulfill withdraw requests from the queue
    function _giveBack() internal {
        
        uint32 counter = recipientCount;
        for(uint8 i=0; i<counter; i++) {
            address recipient = getFromQ();
            _takeBack(recipient);
        }

    }

    // this will add unfulfilled withdraw requests to the queue
    function _takeBackQ(uint256[N_COINS] memory amounts) internal {
        
        for(uint256 i=0; i<N_COINS; i++) {
            if(amounts[i] > 0) {
                amountWithdraw[msg.sender][i] += amounts[i];
                totalWithdraw[i] += amounts[i];
            }
        }

        if(isInQ[msg.sender] != true) {
            recipientCount += 1;
            isInQ[msg.sender] = true;
            addToQ(msg.sender);
        }

    }

    // this will withdraw from curve pool into this contract
    function _withdraw(uint256[N_COINS] memory amounts) internal {
        uint256 max_burn = 0;
        uint256 decimal = 0;
        uint256 _temp = 0;

        for(uint8 i=0; i<N_COINS; i++) {
            decimal = tokens[i].decimals();
            _temp = amounts[i] / 10**decimal;
            max_burn = max_burn + _temp;
        }

        max_burn = max_burn + (max_burn * 2) / 100;
        decimal = PoolToken.decimals();
        max_burn = max_burn * 10**decimal;

        Pool.remove_liquidity_imbalance(amounts, max_burn);
    }

    /* USER FUNCTIONS (exposed to frontend) */

    function supply(uint256[N_COINS] calldata amounts) external {
        require(
            _calcRptAmount(amounts, false) > 0,
            "tokens supplied cannot be zero"
        );
        
        _supply(amounts);
    }

    function requestWithdraw(uint256[N_COINS] calldata amounts) external {
        require(
            _calcRptAmount(amounts, false) > 0,
            "tokens requested cannot be zero"
        );

        uint256[N_COINS] memory poolBalance;
        poolBalance = _getBalances();

        uint256[N_COINS] memory availableWithdraw;
        
        bool checkTime = true;
        bool instant = true;

        uint256 burnAmt;
        burnAmt = _calcRptAmount(amounts, true);
        require(
            rpToken.balanceOf(msg.sender) >= burnAmt, 
            "Insufficient RPT"
        );
        
        
        // check if user is withdrawing before lock period
        for(uint8 i=0; i<N_COINS; i++) {
            if(amounts[i] > 0) {
                for(uint8 j=0; j<supplyTime[msg.sender].length; j++) {
                    if(
                        (now - supplyTime[msg.sender][j].time) 
                        > 
                        (0) // (24 * 60 * 60 * lock_period)
                    ) {
                        availableWithdraw[i] += supplyTime[msg.sender][j].amount[i];
                    }
                }

                if(availableWithdraw[i] < amounts[i]) {
                    checkTime = false;
                }
            }
        }
        require(checkTime, "cannot withdraw before lock period");

        // check if instant withdraw
        for(uint8 i=0; i<N_COINS; i++) {
            if(amounts[i] > poolBalance[i]) {
                instant = false;
            }
        }

        if(instant) {
            rpToken.burn(msg.sender, burnAmt);
            bool result;
            for(uint8 i=0; i<N_COINS; i++) {
                if(amounts[i] > 0) {
                    result = tokens[i].transfer(msg.sender, amounts[i]);
                    require(result);
                    selfBalance[i] -= amounts[i];
                }
            }
        } else {
            _takeBackQ(amounts);
        }
    }

    function checkMintAmount(uint256[N_COINS] calldata amounts) external view returns(uint256) {
        uint256 result = _calcRptAmount(amounts, false);
        return result;
    }

    function checkBurnAmount(uint256[N_COINS] calldata amounts) external view returns(uint256) {
        uint256 result = _calcRptAmount(amounts, true);
        return result;
    }

    function withdrawLoan( 
        uint256[N_COINS] calldata amounts
    ) external {

        require(transactions[msg.sender].gamingCompany == msg.sender, "company not-exist");
        require(transactions[msg.sender].approved, "not approved for loan");
        
        for(uint8 i=0; i<N_COINS; i++) {
            require(
                transactions[msg.sender].remAmt[i] >= amounts[i], 
                "amount requested exceeds amount approved"
            );
        }

        _withdraw(amounts);

        uint8 check = 0;
        for(uint8 i=0; i<N_COINS; i++) {
            if(amounts[i] > 0) {
                tokens[i].transfer(msg.sender, amounts[i]);
                transactions[msg.sender].remAmt[i] -= amounts[i];
            }

            if(transactions[msg.sender].remAmt[i] == 0) {
                check++;
            }
        }

        if(check == 3) {
            // Loan fulfilled, company used all its loan
            transactions[msg.sender].executed = true;
        }
    }

    /* CORE FUNCTIONS (also exposed to frontend but to be called by owner only) */

    function setInitialDeposit() onlyOwner external {
        selfBalance = _getBalances();
    }

    function deposit() onlyOwner external {
        uint256[N_COINS] memory amounts = _getBalances();

        for(uint8 i=0; i<N_COINS; i++) {
            amounts[i] = (amounts[i] * 95) / 100;
            tokens[i].approve(address(Pool), amounts[i]);
        }

        _deposit(amounts);
    }

    function withdraw() onlyOwner external {
        _withdraw(totalWithdraw);
        _giveBack();
    }

    /* ADMIN FUNCTIONS */

}