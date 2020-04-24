var CoinFlipping = artifacts.require("CoinFlipping");
module.exports = function(deployer) {
	deployer.deploy(CoinFlipping, {from:"0x16699e40538BBa5cb79dc76517f409dcA1Bf81D6", gas: 30000000});
};
