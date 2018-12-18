const ganacheRPC = require("ganache-cli");

module.exports = {
  solc: {
    optimizer: {
      enabled: false,
      runs: 200
    }
  },
  networks: {
    ganache: {
      get provider() {
        return ganacheRPC.provider({total_accounts: 10, network_id: 1335, gasLimit:8000000, gasPrice: 1000000000})
      },
      network_id: 1335,
      gas: 8000000,
      gasPrice: 1000000000
    },
    geth_dev: { 
      host: "localhost",
      network_id: 1337,
      port: 8545,
      gas: 6283185, //geth --dev gas limit
      gasPrice: 1000000000
    }
  }
};
