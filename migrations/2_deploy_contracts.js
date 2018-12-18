var ProxyRouter = artifacts.require("ProxyRouter");
var ContractFactory = artifacts.require("ContractFactory");
var TransactionProxy = artifacts.require("TransactionProxy");
var EthereumDIDRegistry = artifacts.require("EthereumDIDRegistry");

module.exports = function(deployer) {

	deployer.deploy(ProxyRouter)
	.then(instance => {
		return instance;
	})
	.then( txRouter => {
		deployer.deploy(EthereumDIDRegistry)
		.then( DIDRegistry => {
			deployer.deploy(ContractFactory)
			.then(Factory => {
				Factory.initialize(DIDRegistry.address)
			})
			return DIDRegistry;
		})
		.then( DIDRegistry => {
			deployer.deploy(TransactionProxy)
			.then(txProxy =>{
				txProxy.initialize(DIDRegistry.address,txRouter.address)
			})
		})
	})
}
