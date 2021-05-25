const { Console } = require("console")
 
const PoolStrategy = artifacts.require('poolStrategy')
const config = require("./../secrets.json");

module.exports = function (deployer, network, accounts) {
  console.log(accounts[0],"accounts");
  deployer.deploy(PoolStrategy,"0x820fb6bEa9BD3634f28a85F706C379834B108F7d",
  ["0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3","0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56","0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d","0x55d398326f99059fF775485246999027B3197955"],
  "0x6E21c1176A8B5A2272F9e53E7A9123C1Db6F9DF2",
  "0x820fb6bEa9BD3634f28a85F706C379834B108F7d",
  "0x0bc3a8239b0a63e945ea1bd6722ba747b9557e56",
  "0xaF4dE8E872131AE328Ce21D909C74705d3Aaf452",
  "0xA7f552078dcC247C2684336020c03648500C6d9F",
  "0xc6a752948627becab5474a10821df73ff4771a49",
  "0x160CAed03795365F3A589f10C379FfA7d75d4E76",
  "0x2d0a931dd088ea108a73901f83065dca81ca474c",
  "0xcce949De564fE60e7f96C85e55177F8B9E4CF61b",
  "0x4076CC26EFeE47825917D0feC3A79d0bB9a6bB5c",
  "0x10ED43C718714eb63d5aA57B78B54704E256024E",
  "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"
  ).then(() => {
    console.log(PoolStrategy.address)
  })
}