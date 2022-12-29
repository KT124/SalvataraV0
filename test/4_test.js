// describe("creating and biding on ETH market item + listing fee 1ETH", function () {
//     it("should disallow deployer to create market item without listing fee", async () => {
//         await expect(await salvaNFT.mintNFTWithRoyalty("ipfs//aaa111ccc", 5000))
//             .to.emit(salvaNFT, "Transfer")
//             .withArgs(ethers.constants.AddressZero, deployer.address, 3);

//         await expect(
//             market.createMarketItemWithEtherPrice(
//                 3,
//                 10,
//                 200,
//                 "ipfs//aaa111ccc",
//                 1665150425,
//                 9965150425,
//                 salvaNFT.address
//             )
//         ).to.be.revertedWith("listing fee required.");
//     });

//     it("should disallow listing already listed token Id 1", async () => {
//         await expect(
//             market.createMarketItemWithEtherPrice(
//                 1,
//                 10,
//                 200,
//                 "ipfs//aaa111ccc",
//                 1665150425,
//                 9965150425,
//                 salvaNFT.address
//             )
//         ).to.be.revertedWith("already listed!");
//     });

//     it("should now allow deployer to create market item with 1ETH listing fee", async () => {
//         await expect(
//             market.createMarketItemWithEtherPrice(
//                 3,
//                 10,
//                 200,
//                 "ipfs//aaa111ccc",
//                 1665150425,
//                 9965150425,
//                 salvaNFT.address,
//                 { value: ethers.utils.parseEther("1.0") }
//             )
//         )
//             .to.emit(market, "MarketItemCreated")
//             .withArgs(deployer.address, 3, 10, 200);
//     });

//     it("should fetch correct TotalplatformFeeInEth of 2ETH", async () => {
//         expect(await market.TotalplatformFeeInEth()).to.be.equal(
//             ethers.utils.parseEther("2.0")
//         );
//     });
// });