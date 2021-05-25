/* const { Console } = require("console")
 
const royaleLP = artifacts.require('RoyaleLP')
const config = require("./../secrets.json");

module.exports = function (deployer, network, accounts) {
  console.log(accounts[0],"accounts");
  deployer.deploy(royaleLP,["0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3","0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56","0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d","0x55d398326f99059fF775485246999027B3197955"],"0xe8e5d5afd4E12772dC2a9DfECcCe7B38db23Dfb4","0x820fb6bEa9BD3634f28a85F706C379834B108F7d").then(() => {
    console.log(royaleLP.address)
  })
} */