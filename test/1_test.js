// const { expect, assert } = require("chai");
// const { ethers } = require("hardhat");
// const { BigNumber } = require("ethers");

// describe("Market Item priced in ERC20", function () {
//   let SalvaNFT,
//     salvaNFT,
//     SalvaCoin,
//     salvaCoin,
//     LibMarket,
//     libMarket,
//     Market,
//     market,
//     owner,
//     account1,
//     account2,
//     account3;

//   before(async () => {
//     [owner, account1, account2, account3] = await ethers.getSigners();

//     SalvaNFT = await ethers.getContractFactory("SalvaNFT");
//     salvaNFT = await SalvaNFT.deploy();
//     await salvaNFT.deployed();
//     console.log(`SalvaNFT deployed at ${salvaNFT.address}`);

//     SalvaCoin = await ethers.getContractFactory("SalvaCoin");
//     salvaCoin = await SalvaCoin.deploy();
//     await salvaCoin.deployed();
//     console.log(`SalvaCoin deployed at ${salvaCoin.address}`);

//     LibMarket = await ethers.getContractFactory("LibMarket");
//     libMarket = await LibMarket.deploy();
//     await libMarket.deployed();
//     console.log(`LibMarket deployed at ${libMarket.address}`);

//     Market = await ethers.getContractFactory("Market", {
//       libraries: {
//         LibMarket: libMarket.address,
//       },
//     });
//     market = await Market.deploy(salvaNFT.address);
//     await market.deployed();
//     console.log(`Market deployed at ${market.address}`);

//     await salvaNFT.setMarketAddress(market.address);
//     const minterRole = await salvaNFT.MINTER_ROLE();
//     await salvaNFT.grantRole(minterRole, account1.address);
//     await salvaNFT.grantRole(minterRole, account2.address);
//   });

//   describe("MarketItem priced in ERC20", () => {
//     // it("should set market fee", async () => {
//     //   await market.setListingFee(10);
//     // })
//     it("should pause the contract", async () => {
//       await market.pause();
//       expect(await market.paused()).to.be.equal(true);
//     });

//     it("should unpause the  contract", async () => {
//       await market.unPause();
//       expect(await market.paused()).to.be.equal(false);
//     });
//     it("should get the SYMBOL of platform", async () => {
//       expect(await market.SYMBOL()).to.be.equal("STCX");
//     });
//     it("should get the MARKET_NAME of platform", async () => {
//       expect(await market.MARKET_NAME()).to.be.equal(
//         "Salvatara NFT Market-Place"
//       );
//     });
//     it("should mint 100 coins to account1, account2 and account3", async () => {
//       await expect(salvaCoin.mint(owner.address, 100))
//         .to.emit(salvaCoin, "Transfer")
//         .withArgs(ethers.constants.AddressZero, owner.address, 100);

//       await salvaCoin.approve(market.address, 100);

//       await expect(salvaCoin.mint(account1.address, 100))
//         .to.emit(salvaCoin, "Transfer")
//         .withArgs(ethers.constants.AddressZero, account1.address, 100);

//       await salvaCoin.connect(account1).approve(market.address, 100);

//       await expect(salvaCoin.mint(account2.address, 100))
//         .to.emit(salvaCoin, "Transfer")
//         .withArgs(ethers.constants.AddressZero, account2.address, 100);

//       await salvaCoin.connect(account2).approve(market.address, 100);

//       await expect(salvaCoin.mint(account3.address, 100))
//         .to.emit(salvaCoin, "Transfer")
//         .withArgs(ethers.constants.AddressZero, account3.address, 100);
//     });

//     /** createMarketItemWithERC20tokenPrice tests starts */

//     it("should owner to createMarketItemWithERC20tokenPrice for token id 1", async () => {
//       await salvaNFT.mintNFTWithRoyalty("ipfs://aja3nalnlndlanflnaf", 5000);

//       await expect(
//         market.createMarketItemWithERC20tokenPrice(
//           salvaCoin.address,
//           salvaNFT.address,
//           1,
//           50,
//           200,
//           "ipfs://aja3nalnlndlanflnaf",
//           1665150425,
//           9965150425,
//           []
//         )
//       )
//         .to.emit(market, "MarketItemCreated")
//         .withArgs(owner.address, 1, 50, 200);
//     });
//     it("should allow account2 to createMarketItemWithERC20tokenPrice for tokenid 3", async () => {
//       const bnToken = await salvaNFT
//         .connect(account2)
//         .mintNFTWithRoyalty("ipfs://knlknafnlanflkanflnaf", 5000);
//       // const token = ethers.utils.formatEther( (BigNumber.from(bnToken)))

//       await expect(
//         market
//           .connect(account2)
//           .createMarketItemWithERC20tokenPrice(
//             salvaCoin.address,
//             salvaNFT.address,
//             3,
//             50,
//             200,
//             "ipfs://knlknafnlanflkanflnaf",
//             1665150425,
//             9965150425,
//             []
//           )
//       )
//         .to.emit(market, "MarketItemCreated")
//         .withArgs(account2.address, 3, 50, 200);
//     });

//     it("should allow a 60 ERC bid from account2 on Owner created item and change ERC20 balances between account2 and market", async () => {
//       await expect(
//         await market.connect(account2).bidWithERC(salvaNFT.address, 1, 60)
//       )
//         .changeTokenBalances(salvaCoin, [account2, market], [-60, 60])
//         .to.emit(market, "BidMade")
//         .withArgs(account2.address, 60, 1);
//     });

//     it("should change the erc market balance to 60 and reduce the account2 erc balance to 40 ", async () => {
//       const marketBal = await salvaCoin.balanceOf(market.address);
//       const account2Bal = await salvaCoin.balanceOf(account2.address);
//       console.log(`market balance: ${marketBal}`);
//       console.log(`account2 balance: ${account2Bal}`);
//       expect(await salvaCoin.balanceOf(market.address)).to.be.equal(60);
//       expect(await salvaCoin.balanceOf(account2.address)).to.be.equal(40);
//     });
//     it("should allow a 70 ERC bid from owner on Account2 created item and change ERC20 balances between owner and market", async () => {
//       await expect(await market.bidWithERC(salvaNFT.address, 3, 70))
//         .changeTokenBalances(salvaCoin, [owner, market], [70, 70])
//         .to.emit(market, "BidMade")
//         .withArgs(owner.address, 70, 3);
//     });

//     it("should increase the market balance to 130 erc and reduce the owner balance to 30 erc", async () => {
//       const marketBal = await salvaCoin.balanceOf(market.address);
//       const ownerBal = await salvaCoin.balanceOf(owner.address);
//       console.log(`market balance: ${marketBal}`);
//       console.log(`owner balance: ${ownerBal}`);
//       expect(await salvaCoin.balanceOf(market.address)).to.be.equal(130);
//       expect(await salvaCoin.balanceOf(owner.address)).to.be.equal(30);
//     });

//     it("should allow a 70 ERC bid from account1 on owner created token id 1 and change ERC balances between account1 and market", async () => {
//       await expect(
//         await market.connect(account1).bidWithERC(salvaNFT.address, 1, 70)
//       )
//         .changeTokenBalances(salvaCoin, [account1, market], [-70, 70])
//         .to.emit(market, "BidMade")
//         .withArgs(account1.address, 70, 1);

//       expect(await salvaNFT.ownerOf(1)).to.be.equal(owner.address);

//       expect(await salvaCoin.balanceOf(market.address)).to.be.equal(200);
//     });

//     it("should increaset the market erc-balance too 200 and reduce the account1 erc balane to 30", async () => {
//       const marketBal = await salvaCoin.balanceOf(market.address);
//       const account1Bal = await salvaCoin.balanceOf(account1.address);
//       console.log(`market balance: ${marketBal}`);
//       console.log(`account1 balance: ${account1Bal}`);
//       expect(await salvaCoin.balanceOf(market.address)).to.be.equal(200);
//       expect(await salvaCoin.balanceOf(account1.address)).to.be.equal(30);
//     });

//     it("should allow owner to accept the highest bid of 70 ERC from account1 and change balances between market and account1", async () => {
//       await expect(await market.acceptBid(salvaNFT.address, 1))
//         .to.emit(market, "MarketItemSold")
//         .withArgs(owner.address, account1.address, 1, 70);

//       expect(await salvaCoin.balanceOf(owner.address)).to.be.equal(100);
//       expect(await salvaCoin.balanceOf(account1.address)).to.be.equal(30);
//       expect(await salvaCoin.balanceOf(market.address)).to.be.equal(130);
//       expect(await salvaCoin.balanceOf(account2.address)).to.be.equal(40);
//     });

//     it("should disallow account1 to withdraw 70 erc bid after its bid has been accepted", async () => {
//       await expect(
//         market.connect(account1).withdrawERC20(salvaCoin.address, 1)
//       ).to.be.revertedWith("Zero ERC20 balance!");
//     });

//     it("should ensure account1 is the new owner of tokenId 1", async () => {
//       console.log(`tokenId one owner: ${await salvaNFT.ownerOf(1)}`);

//       expect(await salvaNFT.ownerOf(1)).to.be.equal(account1.address);
//     });

//     it("should increase the owner erc balance to 100 from 30 and reduce the market erc balance to  130 from 200 ", async () => {
//       const marketBal = await salvaCoin.balanceOf(market.address);
//       const ownerBal = await salvaCoin.balanceOf(owner.address);
//       console.log(`market balance: ${marketBal}`);
//       console.log(`owner balance: ${ownerBal}`);
//       expect(await salvaCoin.balanceOf(market.address)).to.be.equal(130);
//       expect(await salvaCoin.balanceOf(owner.address)).to.be.equal(100);
//     });

//     it("should allow account2 to withdraw unsuccessful bid of 60 erc from market", async () => {
//       expect(await salvaCoin.balanceOf(market.address)).to.equal(130);
//       expect(await salvaCoin.balanceOf(account2.address)).to.equal(40);
//       await expect(
//         await market.connect(account2).withdrawERC20(salvaCoin.address, 1)
//       )
//         .to.emit(market, "ERC20withdrawal")
//         .withArgs(account2.address, 60, salvaCoin.address);

//       expect(await salvaCoin.balanceOf(market.address)).to.equal(70);
//       expect(await salvaCoin.balanceOf(account2.address)).to.equal(100);
//     });

//     it("should increase account2 erc balance to 100 from 40 and reduce the market erc balance to 70 from 130", async () => {
//       const marketBal = await salvaCoin.balanceOf(market.address);
//       const account2Bal = await salvaCoin.balanceOf(account2.address);
//       console.log(`market balance: ${marketBal}`);
//       console.log(`account2 balance: ${account2Bal}`);
//       expect(await salvaCoin.balanceOf(market.address)).to.be.equal(70);
//       expect(await salvaCoin.balanceOf(account2.address)).to.be.equal(100);
//     });

//     it("should allow account2 to accept the 70 erc bid from owner", async () => {
//       console.log(
//         `market erc balance: ${await salvaCoin.balanceOf(market.address)}`
//       );
//       console.log(
//         `owner erc balance: ${await salvaCoin.balanceOf(owner.address)}`
//       );
//       console.log(
//         `account2 erc balance: ${await salvaCoin.balanceOf(account2.address)}`
//       );
//       await expect(
//         await market.connect(account2).acceptBid(salvaNFT.address, 3)
//       )
//         .to.emit(market, "MarketItemSold")
//         .withArgs(account2.address, owner.address, 3, 70);

//       expect(await salvaCoin.balanceOf(owner.address)).to.be.equal(100);
//       expect(await salvaCoin.balanceOf(market.address)).to.be.equal(0);
//       expect(await salvaCoin.balanceOf(account2.address)).to.be.equal(170);
//     });

//     it("should increase account2 erc balance to 170 from 100 and market balane to 0 from 70 ", async () => {
//       console.log(
//         `market erc balance: ${await salvaCoin.balanceOf(market.address)}`
//       );

//       console.log(
//         `account2 erc balance: ${await salvaCoin.balanceOf(account2.address)}`
//       );

//       expect(await salvaCoin.balanceOf(market.address)).to.be.equal(0);
//       expect(await salvaCoin.balanceOf(account2.address)).to.be.equal(170);
//     });

//     it("should disallow owner to withdraw 70 erc from market after owner bid has been accepted", async () => {
//       await expect(
//         market.withdrawERC20(salvaCoin.address, 3)
//       ).to.be.revertedWith("Zero ERC20 balance!");
//     });

//     it("should ensure owner is new owner of tokenId 3", async () => {
//       expect(await salvaNFT.ownerOf(3)).to.be.equal(owner.address);
//     });
//   });
// });
