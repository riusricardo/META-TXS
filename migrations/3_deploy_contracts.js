var ContractFactory = artifacts.require("ContractFactory");
var TransactionProxy = artifacts.require("TransactionProxy");

module.exports = function(deployer) {
	
	var bytecode = '0x0';
	var tx;

	const code = TransactionProxy.bytecode;
	bytecode = code.toString()

	ContractFactory.deployed().then(instance => {
		tx = instance.setBytecode(bytecode)
		return tx;
  	});
};
