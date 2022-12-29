// const { expect } = require("chai");
// const { ethers } = require("hardhat");

// describe("Bid test for Eth and ERC simultaneously", function () {

//   let SalvaNFT,
//     salvaNFT,
//     SalvaCoin,
//     salvaCoin,
//     LibMarket,
//     libMarket,
//     CreateItem,
//     createItem,
//     Bids,
//     bids,
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

//     CreateItem = await hre.ethers.getContractFactory("CreateItem");
//     createItem = await CreateItem.deploy();
//     await createItem.deployed();
//     console.log(`CreateItem deployed at ${createItem.address}`);

//     Bids = await hre.ethers.getContractFactory("Bids");
//     bids = await Bids.deploy();
//     await bids.deployed();
//     console.log(`Bids deployed at ${bids.address}`);

//     Market = await ethers.getContractFactory("Market", {
//       libraries: {
//         LibMarket: libMarket.address,
//         Bids: bids.address,
//         CreateItem: createItem.address,
//       },
//     });
//     market = await Market.deploy(salvaNFT.address);
//     await market.deployed();
//     console.log(`Market deployed at ${market.address}`);

//     await salvaNFT.setMarketAddress(market.address);
//   });




//   describe("creating and biding on ERC20 market item + listing fee 1ETH", function () {
//     it("should mint 100 coins to deployer, account1, account2 and account3 and approve the market for 100ERC", async () => {
//       await salvaCoin.mint(deployer.address, 100);
//       await salvaCoin.mint(account1.address, 100);
//       await salvaCoin.mint(account2.address, 100);
//       await salvaCoin.mint(account3.address, 100);

//       expect(await salvaCoin.balanceOf(deployer.address)).to.be.equal(100);
//       expect(await salvaCoin.balanceOf(account1.address)).to.be.equal(100);
//       expect(await salvaCoin.balanceOf(account2.address)).to.be.equal(100);
//       expect(await salvaCoin.balanceOf(account3.address)).to.be.equal(100);
//       await salvaCoin.approve(market.address, 100);
//       await salvaCoin.connect(account1).approve(market.address, 100);
//       await salvaCoin.connect(account2).approve(market.address, 100);
//       await salvaCoin.connect(account3).approve(market.address, 100);
//     });

//     it("should disallow unauthorized caller to change nft-contract-address", async () => {
//       await expect(
//         market.connect(account1).updateNFTContractAddress(salvaNFT.address)
//       ).to.be.reverted;
//     });
//     it("should allow admin caller to change nft-contract-address", async () => {
//       await market.updateNFTContractAddress(salvaNFT.address);
//     });
//     it("should set platformFee 1 ETH", async () => {
//       await expect(market.setListingFee(ethers.utils.parseUnits("1.0")))
//         .to.emit(market, "ListingFeeModified")
//         .withArgs(ethers.utils.parseUnits("1.0"));
//     });

//     it("should disallow deployer to create market item without listing fee", async () => {
//       await expect(await salvaNFT.mintNFTWithRoyalty("ipfs//aaa111bbb", 5000))
//         .to.emit(salvaNFT, "Transfer")
//         .withArgs(ethers.constants.AddressZero, deployer.address, 1);

//       await expect(
//         market.createMarketItemWithERC20tokenPrice(
//           salvaCoin.address,
//           salvaNFT.address,
//           1,
//           10,
//           200,
//           "ipfs//aaa111bbb",
//           1665150425,
//           9965150425,
//           []
//         )
//       ).to.be.revertedWith("listing fee required.");
//     });

//     it("should now allow deployer to create market item with 10 ERC20 price with listing fee of 1ETH", async () => {
//       await expect(
//         await market.createMarketItemWithERC20tokenPrice(
//           salvaCoin.address,
//           salvaNFT.address,
//           1,
//           10,
//           "ipfs//aaa111bbb",
//           1665150425,
//           9965150425,
//           { value: ethers.utils.parseEther("1.0") }
//         )
//       )
//         .to.emit(market, "MarketItemCreated")
//         .withArgs(deployer.address, 1, 10, 200);
//     });

//     // it("should fetch correct TotalplatformFeeInEth of 1ETH", async () => {
//     //   expect(await market.TotalplatformFeeInEth()).to.be.equal(
//     //     ethers.utils.parseEther("1.0")
//     //   );
//     // });

//     // it("should be zero ERC20 balance for market before bidding starts", async () => {
//     //   const marketBal = await salvaCoin.balanceOf(market.address);
//     //   console.log(marketBal.toString());
//     //   expect(await salvaCoin.balanceOf(market.address)).to.be.equal(0);
//     // });

//     // it("should disallow account1 to bid 10 ERC on owner created market with tokeId 1", async () => {
//     //   await expect(market.connect(account1).bidWithERC(salvaNFT.address, 1, 10))
//     //     .to.be.reverted;
//     // });

//     // it("should disallow seller to bid on its own item", async () => {
//     //   await expect(
//     //     market.bidWithERC(salvaNFT.address, 1, 20)
//     //   ).to.be.revertedWith("Market: owner not allowed!");
//     // });
//     // it("should allow account1 to bid with 20 ERC", async () => {
//     //   await expect(
//     //     await market.connect(account1).bidWithERC(salvaNFT.address, 1, 20)
//     //   )
//     //     .to.changeTokenBalances(salvaCoin, [account1, market], [-20, 20])
//     //     .to.emit(market, "BidMade")
//     //     .withArgs(account1.address, 20, 1);
//     // });

//     // it("should be 20 ERC market balance", async () => {
//     //   const marketBal = await salvaCoin.balanceOf(market.address);
//     //   console.log(marketBal.toString());
//     //   expect(await salvaCoin.balanceOf(market.address)).to.be.equal(20);
//     // });

//     // it("should reduce the ERC balance of account1 to 80 from 100", async () => {
//     //   expect(await salvaCoin.balanceOf(account1.address)).to.be.equal(80);
//     // });

//     // it("should disallow account2 bid on non-listed tokenId ", async () => {
//     //   await expect(
//     //     market.connect(account2).bidWithERC(salvaNFT.address, 11, 20)
//     //   ).to.be.revertedWith("Market: not available!");
//     // });

//     // it("should disallow account2 the same bid as account1 ", async () => {
//     //   await expect(
//     //     market.connect(account2).bidWithERC(salvaNFT.address, 1, 20)
//     //   ).to.be.revertedWith("Bid higher ERC20");
//     // });

//     // it("should allow accout2 25 ERC bid on tokenId 1", async () => {
//     //   await expect(
//     //     await market.connect(account2).bidWithERC(salvaNFT.address, 1, 25)
//     //   )
//     //     .to.changeTokenBalances(salvaCoin, [account2, market], [-25, 25])
//     //     .to.emit(market, "BidMade")
//     //     .withArgs(account2.address, 25, 1);
//     // });

//     // it("should be 45 ERC market balance", async () => {
//     //   const marketBal = await salvaCoin.balanceOf(market.address);
//     //   console.log(marketBal);
//     //   expect(await salvaCoin.balanceOf(market.address)).to.be.equal(45);
//     // });

//     // it("should be down 75 ERC balance account2", async () => {
//     //   const ercBal = await salvaCoin.balanceOf(account2.address);
//     //   console.log(ercBal.toString());
//     //   expect(await salvaCoin.balanceOf(account2.address)).to.be.equal(75);
//     // });

//     /**========================ETH market==================================== */

//     // it("should disallow account1 to create ETH market item without listing fee", async () => {
//     //   const minterRole = await salvaNFT.MINTER_ROLE();
//     //   await salvaNFT.grantRole(minterRole, account1.address);
//     //   expect(await salvaNFT.hasRole(minterRole, account1.address));
//     //   await expect(
//     //     salvaNFT.connect(account1).mintNFTWithRoyalty("ipfs//aaa111ccc", 5000)
//     //   )
//     //     .to.emit(salvaNFT, "Transfer")
//     //     .withArgs(ethers.constants.AddressZero, account1.address, 3);

//     //   await expect(
//     //     market
//     //       .connect(account1)
//     //       .createMarketItemWithEtherPrice(
//     //         3,
//     //         10,
//     //         200,
//     //         "ipfs//aaa111ccc",
//     //         1665150425,
//     //         9965150425,
//     //         salvaNFT.address
//     //       )
//     //   ).to.be.revertedWith("listing fee required.");
//     // });

//     // it("should disallow non-nft owner to create market item ", async () => {
//     //   await expect(
//     //     market.createMarketItemWithEtherPrice(
//     //       3,
//     //       10,
//     //       200,
//     //       "ipfs//aaa111ccc",
//     //       1665150425,
//     //       9965150425,
//     //       salvaNFT.address
//     //     )
//     //   ).to.be.revertedWith("Market: Only-NFT-owner");
//     // });

//     // it("should disallow listing already listed token Id 1", async () => {
//     //   await expect(
//     //     market.createMarketItemWithEtherPrice(
//     //       1,
//     //       10,
//     //       200,
//     //       "ipfs//aaa111ccc",
//     //       1665150425,
//     //       9965150425,
//     //       salvaNFT.address
//     //     )
//     //   ).to.be.revertedWith("already listed!");
//     // });

//     // it("should now allow account1 to create market item with 1ETH listing fee", async () => {
//     //   await expect(
//     //     market
//     //       .connect(account1)
//     //       .createMarketItemWithEtherPrice(
//     //         3,
//     //         10,
//     //         200,
//     //         "ipfs//aaa111ccc",
//     //         1666855022,
//     //         1766855022,
//     //         salvaNFT.address,
//     //         { value: ethers.utils.parseEther("1.0") }
//     //       )
//     //   )
//     //     .to.emit(market, "MarketItemCreated")
//     //     .withArgs(account1.address, 3, 10, 200);
//     // });

//     // it("should fetch correct TotalplatformFeeInEth of 2ETH", async () => {
//     //   expect(await market.TotalplatformFeeInEth()).to.be.equal(
//     //     ethers.utils.parseEther("2.0")
//     //   );
//     // });

//     // /**======================should disallow bidders to withdraw bids while it's stil on========================== */
//     // it("should disallow account1 and account2 to withdraw ERC20 while bid is stil on", async () => {
//     //   await expect(
//     //     market.connect(account1).withdrawERC20(salvaCoin.address, 1)
//     //   ).to.be.revertedWith("Only after bid duration!");
//     //   await expect(
//     //     market.connect(account2).withdrawERC20(salvaCoin.address, 1)
//     //   ).to.be.revertedWith("Only after bid duration!");
//     // });
//   });

//   /** ==================biding on ETH market========================================================= */

//   // it("should disallow tokenId 3 owner account1 to bid on its own item", async () => {

//   //   await expect(
//   //     market.connect(account1).bidwithEther(salvaNFT.address, 3, {
//   //       value: ethers.utils.parseEther("3.0"),
//   //     })
//   //   ).to.be.revertedWith("Market: owner not allowed!");
//   // });
//   // it("should disallow less than min-price Eth bid", async () => {
//   //   await expect(
//   //     market.bidwithEther(salvaNFT.address, 3, {
//   //       value: ethers.utils.parseEther("1.0"),
//   //     })
//   //   ).to.be.revertedWith("Market: owner not allowed!");
//   // });
//   // it("should allow higher bid of 2Eth from deployer", async () => {
//   //   await expect(
//   //     await market.bidwithEther(salvaNFT.address, 3, {
//   //       value: ethers.utils.parseEther("3.0"),
//   //     })
//   //   )
//   //     .to.be.changeEtherBalances(
//   //       [deployer, market],
//   //       [ethers.utils.parseEther("3.0").mul(-1), ethers.utils.parseEther("3.0")]
//   //     )
//   //     .to.emit(market, "BidMade")
//   //     .withArgs(deployer.address, ethers.utils.parseEther("3.0"), 3);
//   // });

//   // it("should disallow premature withdrawal during bid", async () => {
//   //   await expect(market.withdrawEther(3)).to.be.revertedWith(
//   //     "Market: no pending widrawls for this Id"
//   //   );
//   // });

//   // it("should be exactly 2ETH in the market contract", async () => {
//   //   const provider = ethers.provider;
//   //   const marketBal = await provider.getBalance(market.address);

//   //   console.log(marketBal.toString());

//   //   expect(await provider.getBalance(market.address)).to.be.equal(
//   //     ethers.utils.parseEther("2.0")
//   //   );
//   // });


// });
