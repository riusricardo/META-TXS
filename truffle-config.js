const ganacheRPC = require("ganache-cli");

function getProvider() {
    return ganacheRPC.provider({total_accounts: 10, network_id: 35, gasLimit:8000000, gasPrice: 20000000000});
}

module.exports = {
  solc: {
    optimizer: {
      enabled: true,
      runs: 150
    },
    evmVersion: "constantinople"
  },
  networks: {
    ganache: {
      get provider() {
        return getProvider()
      },
      network_id: 35,
      gas: 8000000,
      gasPrice: 20000000000
    },
    ganache_dev: {
      host: "localhost",
      network_id: 1335,
      port: 8545,
      gas: 8000000,
      gasPrice: 1000000000
    },
    geth_dev: { 
      host: "localhost",
      network_id: 1337,
      port: 8545,
      gas: 6283185, //geth --dev initial gas limit.
      gasPrice: 1000000000
    }
  }
};
