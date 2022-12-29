// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");


async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const SalvaCoin = await hre.ethers.getContractFactory("SalvaCoin");

  /**=================================deployment cost estimation starts============================= */

  const gasPrice = await SalvaCoin.signer.getGasPrice();
  console.log(`Current gas price ${gasPrice}`);

  const estimateGas = await SalvaCoin.signer.estimateGas(
    SalvaCoin.getDeployTransaction()
  );

  console.log(`Estimaged gas: ${estimateGas}`);

  const deploymentPrice = gasPrice.mul(estimateGas);

  const deployerBalance = await SalvaCoin.signer.getBalance();
  console.log(
    `Deployer balance: ${ethers.utils.formatEther(deployerBalance)}`
  );
  console.log(
    `Deployment price: ${ethers.utils.formatEther(deploymentPrice)}`
  );

  if (Number(deployerBalance) < Number(deploymentPrice)) {
    throw new Error("You don't have enough balance to deploy this contract.");
  }

  /** ============================deployment cost estimation end========================= */
  const salvaCoin = await SalvaCoin.deploy();
  await salvaCoin.deployed();

  const LibMarket = await hre.ethers.getContractFactory("LibMarket");
  const libMarket = await LibMarket.deploy();
  await libMarket.deployed();


  const CreateItem = await hre.ethers.getContractFactory("CreateItem");
  const createItem = await CreateItem.deploy();
  await createItem.deployed();


  const Bids = await hre.ethers.getContractFactory("Bids");
  const bids = await Bids.deploy();
  await bids.deployed();

  const SalvaNFT = await hre.ethers.getContractFactory("SalvaNFT");
  const salvaNFT = await SalvaNFT.deploy();
  await salvaNFT.deployed();



  const Market = await hre.ethers.getContractFactory("Market", {
    libraries: {
      LibMarket: libMarket.address,
      Bids: bids.address,
      CreateItem: createItem.address,
    },
  });
  const market = await Market.deploy(salvaNFT.address);

  await market.deployed();

  /** setting marketplace address for approvals after mint */

  await salvaNFT.setMarketAddress(market.address);

  console.log("SalvaCoin deployed to:", salvaCoin.address);
  console.log("SalvaNFT deployed to:", salvaNFT.address);
  console.log("Market deployed to:", market.address);
  console.log("LibMarket deployed to:", libMarket.address);
  console.log("CreateItem deployed to:", createItem.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });



// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});



// async function main() {
//   const currentTimestampInSeconds = Math.round(Date.now() / 1000);
//   const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
//   const unlockTime = currentTimestampInSeconds + ONE_YEAR_IN_SECS;

//   const lockedAmount = hre.ethers.utils.parseEther("1");

//   const Lock = await hre.ethers.getContractFactory("Lock");
//   const lock = await Lock.deploy(unlockTime, { value: lockedAmount });

//   await lock.deployed();

//   console.log(
//     `Lock with 1 ETH and unlock timestamp ${unlockTime} deployed to ${lock.address}`
//   );
// }
