const HDWalletProvider = require('@truffle/hdwallet-provider');
const {mnemonic,publicKey,ropstenInfura,rinkebyInfura,mainnet } = require('./secrets.json');
module.exports = {

  networks: {

    ropsten: {
      networkCheckTimeout: 1000000,
      provider: () => new HDWalletProvider(mnemonic, ropstenInfura, 0,2),
      from: publicKey,
      network_id: 3,       // Ropsten's id
      // gasPrice:  1e11,
      gasPrice: 55000000000,
      gas: 5500000,        // Ropsten has a lower block limit than mainnet
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true  ,   // Skip dry run before migrations? (default: false for public nets )
    },
    rinkeby: {
      networkCheckTimeout: 1000000,
      provider: () => new HDWalletProvider(mnemonic, rinkebyInfura, 0,2),
      from: publicKey,
      network_id: 4,       // Ropsten's id
      // gasPrice:  1e11,
      gasPrice: 150000000000,
      gas: 5500000,        // Ropsten has a lower block limit than mainnet
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true  ,   // Skip dry run before migrations? (default: false for public nets )
    },
     mainnet: {
      networkCheckTimeout: 1000000,
      provider: () => new HDWalletProvider(mnemomics, mainnet, 0,2),
      from: publicKey,
      network_id: 1,       // Ropsten's id
      // gasPrice:  1e11,
      gasPrice: 150000000000,
      gas: 5500000,        // Ropsten has a lower block limit than mainnet
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true  ,   // Skip dry run before migrations? (default: false for public nets )
    }, 
   
  },

  
  mocha: {
  },

  compilers: {
    solc: {
      version: "^0.6.0",    // Fetch exact version from solc-bin (default: truffle's version)
      /* settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      } */
    } 
  }
};