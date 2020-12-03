const { assert } = require('chai');

const DaiToken = artifacts.require('DaiToken');
const UsdcToken = artifacts.require('UsdcToken');
const UsdtToken = artifacts.require('UsdtToken');
const CrvToken = artifacts.require('PoolToken');
const RpToken = artifacts.require('RPToken');

const CrvPool = artifacts.require('StableSwap3Pool');
const RoyaleLP = artifacts.require('RoyaleLP');
const MultiSig = artifacts.require('multiSig');

function toDai(n) {
    return web3.utils.toWei(n, 'ether');
}

function toUsd(n) {
    let result = parseFloat(n) * 1e6;
    return result.toString();
}

contract('RoyaleLP', ([owner, signeeOne, signeeTwo, gamer, investorOne, investorTwo]) => {

    let daiToken, usdcToken, usdtToken, crvToken, crvPool;
    let royaleLP, multiSig, rpToken;

    before(async() => {
        // Deploying Tokens
        daiToken = await DaiToken.new();
        usdcToken = await UsdcToken.new();
        usdtToken = await UsdtToken.new();
        crvToken = await CrvToken.new("Curve Token", "CRV", 18, 0);
        rpToken = await RpToken.new();

        // Deploying Curve 3Pool
        crvPool = await CrvPool.new(
            owner,
            [daiToken.address, usdcToken.address, usdtToken.address],
            crvToken.address,
            200, 
            4000000, 
            5000000000, 
        );

        // Deploying RoyaleLP contract
        royaleLP = await RoyaleLP.new(
            crvPool.address, 
            [daiToken.address, usdcToken.address, usdtToken.address],
            crvToken.address,
            rpToken.address
        );

    });

    describe('Setting Up Curve Pool', async() => {
        describe('DaiToken deployment', async() => {
            it('has a name', async() => {
                let name = await daiToken.name();
                assert.equal(name, "Mock DAI Token");
            });
        });
    
        describe('UsdcToken deployment', async() => {
            it('has a name', async() => {
                let name = await usdcToken.name();
                assert.equal(name, "Mock USDC Token");
            });
        });
    
        describe('UsdtToken deployment', async() => {
            it('has a name', async() => {
                let name = await usdtToken.name();
                assert.equal(name, "Mock USDT Token");
            });
        });
    
        describe('CrvToken deployment', async() => {
            it('has a name', async() => {
                let name = await crvToken.name();
                assert.equal(name, "Curve Token");
            });
    
            it('has set minter', async() => {
                await crvToken.set_minter(crvPool.address); 
    
                result = await crvToken.minter();
                assert.equal(result.toString(), crvPool.address);
            })
        });
    
        describe('CrvPool deployment', async() => {
            it('has initial liquidity', async() => {
                await daiToken.approve(crvPool.address, toDai('50000'));
                await usdcToken.approve(crvPool.address, toUsd('20000'));
                await usdtToken.approve(crvPool.address, toUsd('20000'));
    
                const amounts = [toDai("50000"), toUsd("20000"), toUsd("20000")];
                await crvPool.add_liquidity(amounts, toDai("20000"), { from: owner });
    
                mintAmount = await crvPool.calc_token_amount(amounts, 1);
                supply = await crvToken.totalSupply();
                console.log(supply.toString());
                assert.equal(mintAmount.toString(), supply.toString());
            });
        })
        
        describe('RPToken deployment', async() => {
            it('has a name', async() => {
                let name = await rpToken.name();
                assert.equal(name, "Royale Protocol");
            });
        });
    });

    describe('Initial Set Up', async() => {
        it('Supply each of 1000 tokens to investorOne', async() => {
            await daiToken.transfer(investorOne, toDai('1000'), { from: owner });
            await usdcToken.transfer(investorOne, toUsd('1000'), { from: owner });
            await usdtToken.transfer(investorOne, toUsd('1000'), { from: owner });

            result = await daiToken.balanceOf(investorOne);
            assert.equal(result, toDai('1000'));

            result = await usdcToken.balanceOf(investorOne);
            assert.equal(result, toUsd('1000'));

            result = await usdtToken.balanceOf(investorOne);
            assert.equal(result, toUsd('1000'));
        });

        it('Supply each of 1000 tokens to investorTwo', async() => {
            await daiToken.transfer(investorTwo, toDai('1000'), { from: owner });
            await usdcToken.transfer(investorTwo, toUsd('1000'), { from: owner });
            await usdtToken.transfer(investorTwo, toUsd('1000'), { from: owner });

            result = await daiToken.balanceOf(investorTwo);
            assert.equal(result, toDai('1000'));

            result = await usdcToken.balanceOf(investorTwo);
            assert.equal(result, toUsd('1000'));

            result = await usdtToken.balanceOf(investorTwo);
            assert.equal(result, toUsd('1000'));
        });

        it('Supply each of 1000 tokens to RoyaleLP', async() => {
            await daiToken.transfer(royaleLP.address, toDai('1000'), { from: owner });
            await usdcToken.transfer(royaleLP.address, toUsd('1000'), { from: owner });
            await usdtToken.transfer(royaleLP.address, toUsd('1000'), { from: owner });

            result = await daiToken.balanceOf(royaleLP.address);
            assert.equal(result, toDai('1000'));

            result = await usdcToken.balanceOf(royaleLP.address);
            assert.equal(result, toUsd('1000'));

            result = await usdtToken.balanceOf(royaleLP.address);
            assert.equal(result, toUsd('1000'));

            await royaleLP.setInitialDeposit();
        });

        it('Initial RPT mint', async() => {
            await rpToken.mint(royaleLP.address, toDai('300'));
        });
    });

    describe('RoyaleLP Testing', async() => {

        describe('Deposit Test', async() => {
            it('investorOne added funds to RoyaleLP', async() => {
                await daiToken.approve(
                    royaleLP.address, toDai('500'), { from: investorOne });
                await usdcToken.approve(
                    royaleLP.address, toUsd('500'), { from: investorOne });
                await usdtToken.approve(
                    royaleLP.address, toUsd('500'), { from: investorOne }); 
                
                await royaleLP.supply(
                    [toDai('500'), toUsd('500'), toUsd('500')], 
                    { from: investorOne }
                );

                // Check balances of RoyaleLP
                result = await daiToken.balanceOf(royaleLP.address);
                assert.equal(result.toString(), toDai('1500'));
    
                result = await usdcToken.balanceOf(royaleLP.address);
                assert.equal(result.toString(), toUsd('1500'));
    
                result = await usdtToken.balanceOf(royaleLP.address);
                assert.equal(result.toString(), toUsd('1500'));
                
                // Check balances of InvestorOne
                result = await daiToken.balanceOf(investorOne);
                assert.equal(result.toString(), toDai('500'));
    
                result = await usdcToken.balanceOf(investorOne);
                assert.equal(result.toString(), toUsd('500'));
    
                result = await usdtToken.balanceOf(investorOne);
                assert.equal(result.toString(), toUsd('500'));
            });

            it('investorTwo added funds to RoyaleLP', async() => {
                await daiToken.approve(
                    royaleLP.address, toDai('200'), { from: investorTwo });
                // await usdcToken.approve(
                //     royaleLP.address, toUsd('500'), { from: investorTwo });
                // await usdtToken.approve(
                //     royaleLP.address, toUsd('500'), { from: investorTwo }); 
                
                await royaleLP.supply(
                    [toDai('200'), toUsd('0'), toUsd('0')], 
                    { from: investorTwo }
                );

                // Check balances of RoyaleLP
                result = await daiToken.balanceOf(royaleLP.address);
                assert.equal(result.toString(), toDai('1700'));
    
                result = await usdcToken.balanceOf(royaleLP.address);
                assert.equal(result.toString(), toUsd('1500'));
    
                result = await usdtToken.balanceOf(royaleLP.address);
                assert.equal(result.toString(), toUsd('1500'));
                
                // Check balances of InvestorTwo
                result = await daiToken.balanceOf(investorTwo);
                assert.equal(result.toString(), toDai('800'));
    
                result = await usdcToken.balanceOf(investorTwo);
                assert.equal(result.toString(), toUsd('1000'));
    
                result = await usdtToken.balanceOf(investorTwo);
                assert.equal(result.toString(), toUsd('1000'));
            });

            it('investorOne recieved RPT', async() => {
                result = await rpToken.balanceOf(investorOne);
                console.log(result.toString());

                // result = await royaleLP.totalRPT();
                // console.log(result.toString());
            });
            
            it('investorTwo recieved RPT', async() => {
                result = await rpToken.balanceOf(investorTwo);
                console.log(result.toString());

                // result = await royaleLP.totalRPT();
                // console.log(result.toString());
            });

            it('Supplied funds to 3pool', async() => {
                await royaleLP.deposit();
                
                result = await daiToken.balanceOf(royaleLP.address);
                assert.equal(result.toString(), toDai('85'));
    
                result = await usdcToken.balanceOf(royaleLP.address);
                assert.equal(result.toString(), toUsd('75'));
    
                result = await usdtToken.balanceOf(royaleLP.address);
                assert.equal(result.toString(), toUsd('75'));
                
                lpCRV = await crvToken.balanceOf(royaleLP.address);
                console.log(`RoyaleLP CRV balance: ${lpCRV / 1e18}`);
            });
        });

        describe('MultiSig Initiation', async() => {
            // it('set LP contract', async() => {
            //     await royaleLP.setRoyaleLPAddress(royaleLP.address);
            // });

            it('Add first Signee', async() => {
                await royaleLP.addSignee(signeeOne);

                result = await royaleLP.signees(0);
                assert.equal(result, signeeOne);
            });

            it('Add second Signee', async() => {
                await royaleLP.addSignee(signeeTwo);

                result = await royaleLP.signees(1);
                assert.equal(result, signeeTwo);
            });

            it('set required signee', async() => {
                await royaleLP.setRequiredSignee(2);

                result = await royaleLP.required();
                assert.equal(result, 2);
            });
        });

        describe('Loan withdraw test', async() => {

            it('gamer requests for loan', async() => {
                const amtToWithdraw = [toDai('100'), toUsd('100'), toUsd('100')];
                
                await royaleLP.requestLoan(
                    amtToWithdraw, { from: gamer });

                result = await royaleLP.transactionCount();
                assert.equal(result.toString(), "1");
            });

            it('gamer signs', async() => {
                await royaleLP.signTransaction({ from: gamer });

                result = await royaleLP.getTransactionDetail(gamer);
                console.log("Before Approval: ", result);
            });

            it('signeeOne signs', async() => {
                await royaleLP.confirmLoan(gamer, { from: signeeOne });
            });

            it('signeeTwo signs', async() => {
                await royaleLP.confirmLoan(gamer, { from: signeeTwo });
            });

            it('loan approved', async() => {
                result = await royaleLP.checkLoanApproved(gamer);
                assert.equal(result, true);

                result = await royaleLP.getTransactionDetail(gamer);
                console.log("After approval: ", result);
            });

        });

        describe('Withdraw Test', async() => {
            it('Drop a withdraw request', async() => {
                amounts = [toDai('400'), toUsd('400'), toUsd('400')];
                await royaleLP.requestWithdraw(amounts, { from: investorOne });

                result = await royaleLP.isInQ(investorOne);
                assert.equal(result, true);

                result = await daiToken.balanceOf(investorOne);
                console.log(result.toString());
                result = await usdcToken.balanceOf(investorOne);
                console.log(result.toString());
                result = await usdtToken.balanceOf(investorOne);
                console.log(result.toString());

                result = await royaleLP.totalWithdraw(0);
                assert.equal(result.toString(), toDai('400'));

                result = await royaleLP.totalWithdraw(1);
                assert.equal(result.toString(), toUsd('400'));

                result = await royaleLP.totalWithdraw(2);
                assert.equal(result.toString(), toUsd('400'));
            });

            it('Withdraw from 3pool and fulfill withdraw request', async() => {
                await royaleLP.withdraw();

                result = await daiToken.balanceOf(investorOne);
                console.log(result.toString());
                result = await usdcToken.balanceOf(investorOne);
                console.log(result.toString());
                result = await usdtToken.balanceOf(investorOne);
                console.log(result.toString());

                result = await rpToken.balanceOf(investorOne);
                console.log(result.toString());

                result = await daiToken.balanceOf(royaleLP.address);
                assert.equal(result.toString(), toDai('85'));

                result = await usdcToken.balanceOf(royaleLP.address);
                assert.equal(result.toString(), toUsd('75'));

                result = await usdtToken.balanceOf(royaleLP.address);
                assert.equal(result.toString(), toUsd('75'));

                lpCRV = await crvToken.balanceOf(royaleLP.address);
                console.log(`RoyaleLP CRV balance: ${lpCRV / 1e18}`);
            });
        })

    });

});