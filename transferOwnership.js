// 1. Double check addresses
// 2. In the REMIX compile IOwned
// 3. Right click on the script name and hit "Run" to execute
(async () => {
	try {
		const newOwner = "0x8295aDa05d34E9205986aE4f69Bc0615bdaaa027";
		const calculator = "0xdc436261C356E136b1671442d0bD0Ae183a6d77D";
		const elite = "0xbFDF833E65Bd8B27c84fbE55DD17F7648C532168";
		const rooted = "0xCb5f72d37685C3D5aD0bB5F982443BC8FcdF570E"
		const feeSplitter = "0x89BF266B932a4419985E4c5FDf7b06555519f036";
		const singleSideLiquidityAdder = "0xf5635E53Cab4F6e2D62198F4678206020b7675F1"
		const stakingToken = "0xc328f44ecaCE72cdeBc3e8E86E6705604BE2d2e1"
		const transferGate = "0x621642243CC6bE2D18b451e2386c52d1e9f7eDF6";
		const vault = "0x3B2688B05B40C23bc5EA11b116733cD282450207";
		const rootedRouter = "0x04A2fAB8dD40EEE62A12ce8692853e291ddbF54A"

		const signer = (new ethers.providers.Web3Provider(web3Provider)).getSigner();

		const ownedMetadata = JSON.parse(await remix.call('fileManager', 'getFile', `browser/artifacts/IOwned.json`));
		const ownedFactory = new ethers.ContractFactory(ownedMetadata.abi, ownedMetadata.data.bytecode.object, signer);
		const owned = [
			calculator,
			elite,
			rooted,
			feeSplitter,
			singleSideLiquidityAdder,
			stakingToken,
			transferGate,
			vault,
			rootedRouter
		];

		const calculatorContract = await ownedFactory.attach(calculator);
		const gas = await calculatorContract.estimateGas.transferOwnership(newOwner);
		const increasedGas = gas.toNumber() * 1.5;

		for (var i = 0; i < owned.length; i++) {
			const contract = await ownedFactory.attach(owned[i]);
			contract.transferOwnership(newOwner, { gasLimit: increasedGas });
		}

		console.log('Done!');
	}
	catch (e) {
		console.log(e)
	}
})()