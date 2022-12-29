const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

describe("Market Item priced in ETH with platform fee", function () {
  let SalvaNFT,
    salvaNFT,
    SalvaCoin,
    salvaCoin,
    LibMarket,
    libMarket,
    CreateItem,
    createItem,
    Bids,
    bids,
    Market,
    market,
    owner,
    account1,
    account2,
    account3;

  before(async () => {
    [owner, account1, account2, account3] = await ethers.getSigners();

    SalvaNFT = await ethers.getContractFactory("SalvaNFT");
    salvaNFT = await SalvaNFT.deploy();
    await salvaNFT.deployed();
    console.log(`SalvaNFT deployed at ${salvaNFT.address}`);

    SalvaCoin = await ethers.getContractFactory("SalvaCoin");
    salvaCoin = await SalvaCoin.deploy();
    await salvaCoin.deployed();
    console.log(`SalvaCoin deployed at ${salvaCoin.address}`);

    LibMarket = await ethers.getContractFactory("LibMarket");
    libMarket = await LibMarket.deploy();
    await libMarket.deployed();
    console.log(`LibMarket deployed at ${libMarket.address}`);

    CreateItem = await hre.ethers.getContractFactory("CreateItem");
    createItem = await CreateItem.deploy();
    await createItem.deployed();
    console.log(`CreateItem deployed at ${createItem.address}`);

    Bids = await hre.ethers.getContractFactory("Bids");
    bids = await Bids.deploy();
    await bids.deployed();
    console.log(`Bids deployed at ${bids.address}`);

    Market = await ethers.getContractFactory("Market", {
      libraries: {
        LibMarket: libMarket.address,
        Bids: bids.address,
        CreateItem: createItem.address,
      },
    });
    market = await Market.deploy(salvaNFT.address);
    await market.deployed();
    console.log(`Market deployed at ${market.address}`);

    await salvaNFT.setMarketAddress(market.address);
  });

  /** NFT fuctions and Create marketItem with Eth tests */

  describe("SalvaNFT, market Item priced in Eth with marekt fee", () => {
    it("should pause the contract", async () => {
      await market.pause();
      expect(await market.paused()).to.be.equal(true);
    });

    it("should unpause the  contract", async () => {
      await market.unPause();
      expect(await market.paused()).to.be.equal(false);
    });
    it("should set platformFee 1 ETH", async () => {
      await expect(market.setListingFee(ethers.utils.parseUnits("1.0")))
        .to.emit(market, "ListingFeeModified")
        .withArgs(ethers.utils.parseUnits("1.0"));
    });

    it("should ensure platform fee is set to 1 ETH", async () => {
      expect(await market.listingFee()).to.be.equal(
        ethers.utils.parseEther("1.0")
      );
    });

    it("should ensure platform fee is 1 ETH", async () => {
      expect(await market.TotalplatformFeeInEth()).to.be.equal(
        ethers.utils.parseEther("0.0")
      );
    });

    it("should allow owner to mint with Roaylty ", async () => {
      await expect(salvaNFT.mintNFTWithRoyalty("ipfs://lkanlanfklnlafja", 5000))
        .to.emit(salvaNFT, "Transfer")
        .withArgs(ethers.constants.AddressZero, owner.address, 1);

      expect(await salvaNFT._recipient()).to.be.equal(owner.address);

      const res = await salvaNFT.royalties(1);
    });

    it("should disallow the NON-owner to burn its nft", async () => {
      await expect(salvaNFT.connect(account1).burn(1)).to.be.revertedWith(
        "Only owner!"
      );
    });

    it("should allow owner to burn its own nft", async () => {
      await expect(salvaNFT.burn(1))
        .to.emit(salvaNFT, "Transfer")
        .withArgs(owner.address, ethers.constants.AddressZero, 1);
    });

    it("should ensure owner balance is zero after burn", async () => {
      expect(await salvaNFT.balanceOf(owner.address)).to.be.equal(0);
    });

    it("should allow owner to mint with Roaylty 2nd time", async () => {
      await expect(salvaNFT.mintNFTWithRoyalty("ipfs://lkanlanfklnlafja", 50))
        .to.emit(salvaNFT, "Transfer")
        .withArgs(ethers.constants.AddressZero, owner.address, 3);

      expect(await salvaNFT._recipient()).to.be.equal(owner.address);
    });

    it("should disallow to mint with the same uri second time", async () => {
      await expect(
        salvaNFT.mintNFTWithRoyalty("ipfs://lkanlanfklnlafja", 10)
      ).to.be.revertedWith("uri already minted!");
    });

    it("should disallow owner to create a createMarketItemWithEtherPrice without listing fee", async () => {

      await helpers.time.increaseTo(1672079400); // fixing startime at the start of the test

    
      await expect(
        market.createMarketItemWithEtherPrice(
          3,
          100,
          "ipfs://lkanlanfklnlafja",
          1672079400,
          1672083000,
          salvaNFT.address
        )
      ).to.be.reverted;
    });
    it("should allow owner to create a createMarketItemWithEtherPrice with 1ETH listing fee", async () => {
      await expect(
        market.createMarketItemWithEtherPrice(
          3,
          100,
          "ipfs://lkanlanfklnlafja",
          1665125423,
          1965125423,
          salvaNFT.address,
          { value: ethers.utils.parseEther("1.0") }
        )
      )
        .to.emit(market, "MarketItemCreated")
        .withArgs(owner.address, 3, 100);
    });

    it("should be 1ETH TotalplatformFeeInEth withdrawable for market admin", async () => {
      expect(await market.TotalplatformFeeInEth()).to.be.equal(
        ethers.utils.parseEther("1.0")
      );
    });

    it("should set platformFee to zero", async () => {
      await expect(market.setListingFee(0))
        .to.emit(market, "ListingFeeModified")
        .withArgs(0);
    });

    it("should allow an initial bid of 1 Eth and change balanes of market and account1", async () => {
      // await expect(
      //   market.connect(account1).makeAbid(salvaNFT.address, 1, 0, {
      //     value: ethers.utils.parseUnits("1.0"),
      //   })
      // )
      //   .to.emit(market, "BidMade")
      //   .withArgs(account1.address, "1000000000000000000", 1);
      await expect(
        await market.connect(account1).bidwithEther(salvaNFT.address, 3, {
          value: ethers.utils.parseUnits("1.0"),
        })
      ).to.changeEtherBalances(
        [account1, market],
        [ethers.utils.parseUnits("1.0").mul(-1), ethers.utils.parseUnits("1.0")]
      );
    });

    it("should disallow another bid from differenct account2 with same ether value as account1", async () => {
      await expect(
        market.connect(account2).bidwithEther(salvaNFT.address, 3, {
          value: ethers.utils.parseUnits("1.0"),
        })
      ).to.be.revertedWith("Increase ETH value");
    });

    it("should allow a higher bid of 2 Eth from differenct account2  and change balances of account2 and market", async () => {
      await expect(
        await market.connect(account2).bidwithEther(salvaNFT.address, 3, {
          value: ethers.utils.parseUnits("2.0"),
        })
      ).to.changeEtherBalances(
        [account2, market],
        [ethers.utils.parseUnits("2.0").mul(-1), ethers.utils.parseUnits("2.0")]
      );
    });

    it("should disallow fund withdrawal during bid period and revert successfuly", async () => {
      await expect(
        market.connect(account1).withdrawEther(3)
      ).to.be.revertedWith("Only after bid duration!");
    });

    it("should allow owner to accept bid the highest bid from account 2 and change balances and transfer NFT", async () => {
      // await expect(market.acceptBid(salvaNFT.address, 1))
      //   .to.emit(market, "MarketItemSold")
      //   .withArgs(
      //     owner.address,
      //     account1.address,
      //     1,
      //     ethers.utils.parseUnits("1.0")
      //   );
      await expect(
        await market.acceptBid(salvaNFT.address, 3)
      ).to.changeEtherBalances(
        [market, owner],
        [ethers.utils.parseUnits("2.0").mul(-1), ethers.utils.parseUnits("2.0")]
      );

      expect(await salvaNFT.ownerOf(3)).to.equal(account2.address);
    });

    it("should disallow first bidder account1 to withdraw bid of 1ETh with incorrect tokenId", async () => {
      await expect(
        market.connect(account1).withdrawEther(1)
      ).to.be.revertedWith("Market: no pending widrawls for this Id");
    });
    it("should allow first bidder account1 to withdraw bid of 1ETh", async () => {
      await expect(market.connect(account1).withdrawEther(3))
        .to.emit(market, "Etherwithdrawal")
        .withArgs(account1.address, ethers.utils.parseUnits("1.0"));
    });
    it("should allow createMarketItemWithEtherPrice by the new owner of nft account2", async () => {
      await salvaNFT.connect(account2).approve(market.address, 3);
      await expect(
        market
          .connect(account2)
          .createMarketItemWithEtherPrice(
            3,
            100,
            "ipfs://lkanlanfklnlafja",
            1665125423,
            1965125423,
            salvaNFT.address
          )
      )
        .to.emit(market, "MarketItemCreated")
        .withArgs(account2.address, 3, 100);
    });

    it("should allow a bid of 1Eth from account1 and change of balances between account1 and market", async () => {
      // await expect(
      //   await market.connect(account1).makeAbid(salvaNFT.address, 1, 0, {
      //     value: ethers.utils.parseUnits("1.0"),
      //   })
      // )
      //   .to.emit(market, "BidMade")
      //   .withArgs(account1.address, ethers.utils.parseUnits("1.0"), 1);

      await expect(
        market.connect(account1).bidwithEther(salvaNFT.address, 3, {
          value: ethers.utils.parseUnits("1.0"),
        })
      )
        .to.changeEtherBalances(
          [account1, market],
          [
            ethers.utils.parseUnits("1.0").mul(-1),
            ethers.utils.parseUnits("1.0"),
          ]
        ).and
        .to.emit(market, "BidMade")
        .withArgs(account1.address, ethers.utils.parseUnits("1.0"), 3);
    });

    it("should allow account3 to make a higher bid  of 2 Eth and change balances between market and account3", async () => {
      await expect(
        market.connect(account3).bidwithEther(salvaNFT.address, 3, {
          value: ethers.utils.parseUnits("2.0"),
        })
      )
        .to.changeEtherBalances(
          [account3, market],
          [
            ethers.utils.parseUnits("2.0").mul(-1),
            ethers.utils.parseUnits("2.0"),
          ]
        )
        .to.emit(market, "BidMade")
        .withArgs(account3.address, ethers.utils.parseUnits("2.0"), 3);
    });

    it("should disallow highest bidder account3 to withdraw value prior to bid end", async () => {
      await expect(
        market.connect(account3).withdrawEther(3)
      ).to.be.revertedWith("Only after bid duration!");
    });
    it("should allow highest bidder account1 to withdraw value prior to bid end", async () => {
      await expect(
        market.connect(account1).withdrawEther(3)
      ).to.be.revertedWith("Only after bid duration!");
    });

    
    

    it("should allow nft owner account2 to accept bid from account3 and change balance between creator, account3, and makret", async () => {
      const marketBal = ethers.utils.parseUnits("2.0");
      console.log(`MarketBal: ${ethers.utils.formatEther(marketBal)}`);

      const royalty = await salvaNFT.royaltyInfo(
        3,
        ethers.utils.parseEther("2.0")
      );

      console.log("Royalty amount: ", royalty[1].toString() / 10 ** 18);

      console.log("RoyaltyAmount: ", ethers.utils.formatEther(royalty[1]));

      const account2Bal = marketBal.sub(royalty[1]);
      console.log(`Account2Bal: ${ethers.utils.formatEther(royalty[1])}`);

      await expect(
        await market.connect(account2).acceptBid(salvaNFT.address, 3)
      ).to.changeEtherBalances(
        [market, account2, owner],
        [marketBal.div(-1), account2Bal, royalty[1]]
      );
    });

    it("should allow account1 to withdraw unsuccessful bid of 1Eth from market", async () => {
      await expect(market.connect(account1).withdrawEther(3))
        .to.emit(market, "Etherwithdrawal")
        .withArgs(account1.address, ethers.utils.parseEther("1.0"));
    });
  });
});
