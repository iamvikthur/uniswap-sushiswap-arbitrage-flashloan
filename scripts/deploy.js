const { ethers } = require("hardhat");

async function main(){
  const [deployer] = ethers.getSigners();

  console.log("!!! DEPLOYING CONTRACTS WITH THE ACCOUNT:", deployer.address);
  console.log("!!! ACCOUNT BALANCE:", (await deployer.getBalance()).toString());

  const Flashswap = await ethers.getContractFactory("UniswapV2ShushiFlashSwap");
  const flashSwap = await Flashswap.deploy();
  await flashSwap.deployed();

  console.log("!!! CONTRACT ADDRESS:", flashSwap.address);

}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error);
  process.exit(1);
});
