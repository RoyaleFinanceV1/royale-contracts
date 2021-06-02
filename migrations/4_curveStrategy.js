const { Console } = require("console")
 
const aaveStrategy = artifacts.require('AaveStrategy')
const config = require("./../secrets.json");

module.exports = function (deployer, network, accounts) {
  console.log(accounts[0],"accounts");
  deployer.deploy(aaveStrategy,"0x73b49d50d223E7F21daFA7219B230807f3F6EB58",
  ["0x8f3cf7ad23cd3cadbd9735aff958023239c6a063","0x2791bca1f2de4661ed88a30c99a7a9449aa84174","0xc2132d05d31c914a87c6611c10748aeb04b58e8f"],
  "0xe2c046Dc3e36479082895AE2786738937C1158A8",
  "0x73b49d50d223E7F21daFA7219B230807f3F6EB58",
  "0x445FE580eF8d70FF569aB36e80c647af338db351",
  "0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171",
  "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
  "0xe381C25de995d62b453aF8B931aAc84fcCaa7A62",
  "0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429",
  "0x4c28f48448720e9000907bc2611f73022fdce1fa"
  ).then(() => {
    console.log(aaveStrategy.address)
  })
}