/* const { Console } = require("console")
 
const RPToken = artifacts.require('RPToken')
const config = require("./../secrets.json");

module.exports = function (deployer, network, accounts) {
  console.log(accounts[0],"accounts");
  deployer.deploy(RPToken,"0x820fb6bEa9BD3634f28a85F706C379834B108F7d").then(() => {
    console.log(RPToken.address)
  })
} */