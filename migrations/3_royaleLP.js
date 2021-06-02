/* const { Console } = require("console")
 
const royaleLP = artifacts.require('RoyaleLP')
const config = require("./../secrets.json");

module.exports = function (deployer, network, accounts) {
  console.log(accounts[0],"accounts");
  deployer.deploy(royaleLP,
  ["0x8f3cf7ad23cd3cadbd9735aff958023239c6a063","0x2791bca1f2de4661ed88a30c99a7a9449aa84174","0xc2132d05d31c914a87c6611c10748aeb04b58e8f"],
  "0x290642a4d8BBFEeF5fD4B717f8453Fcf95A6101E",
  "0x73b49d50d223E7F21daFA7219B230807f3F6EB58").then(() => {
    console.log(royaleLP.address)
  })
} */