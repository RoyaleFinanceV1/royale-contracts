const DaiToken = artifacts.require("DaiToken");
const UsdcToken = artifacts.require("UsdcToken");
const UsdtToken = artifacts.require("UsdtToken");
const CrvToken = artifacts.require('PoolToken');
const RpToken = artifacts.require('RPToken');

const CrvPool = artifacts.require('StableSwap3Pool');
const MultiSig = artifacts.require('multiSig');
const RoyaleLP = artifacts.require('RoyaleLP');

const address = require('../addresses.json');

module.exports = async function (deployer, network, accounts) {
  
  // await deployer.deploy(DaiToken);
  // const daiToken = await DaiToken.deployed();

  // await deployer.deploy(UsdcToken);
  // const usdcToken = await UsdcToken.deployed();

  // await deployer.deploy(UsdtToken);
  // const usdtToken = await UsdtToken.deployed();

  // await deployer.deploy(CrvToken, "Curve Token", "CRV", 18, 0);
  // const crvToken = await CrvToken.deployed();

  // await deployer.deploy(RpToken);
  // const rpToken = await RpToken.deployed();  

  // await deployer.deploy(CrvPool,
  //   accounts[0],
  //   // [daiToken.address, usdcToken.address, usdtToken.address],
  //   [address.mDai, address.mUsdc, address.mUsdt],
  //   // crvToken.address,
  //   address.CRV,
  //   200, 
  //   4000000, 
  //   5000000000,
  // );
  // const crvPool = await CrvPool.deployed();

  await deployer.deploy(
    RoyaleLP, 
    // crvPool.address, 
    address.CRVPool,
    // [daiToken.address, usdcToken.address, usdtToken.address],
    [address.mDai, address.mUsdc, address.mUsdt],
    // crvToken.address,
    address.CRV,
    // rpToken.address
    address.RPToken
  );

  // await deployer.deploy(MultiSig);
};
