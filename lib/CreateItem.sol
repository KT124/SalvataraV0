// SPDX-License-Identifier: MIT

pragma solidity =0.8.13;

import "../interfaces/IMarket.sol";

library CreateItem {
    function createMarketItemWithEtherPrice(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        uint256 _tokenId,
        uint256 _price,
        string memory _uri,
        uint256 _bidStartsAt,
        uint256 _bidEndsAt,
        address _nftContract
    ) external {
        tokenIdToMarketItem[_tokenId] = MarketItem({
            tokenId: _tokenId,
            minPrice: _price,
            uri: _uri,
            seller: payable(msg.sender),
            buyer: payable(address(0)),
            NFTcontract: _nftContract,
            paymentToken: PaymentToken(address(0), 0),
            bidStartsAt: _bidStartsAt,
            bidEndsAt: _bidEndsAt,
            highestBid: 0,
            isBidActive: true,
            highestBidder: address(0),
            isERC20exits: false,
            isListed: true
        });
    }

    function createMarketItemWithERC20tokenPrice(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        address _paymentToken,
        address _nftContract,
        uint256 _tokenId,
        uint256 _cost,
        string memory _uri,
        uint256 _bidStartsAt,
        uint256 _bidEndsAt
    ) external {
        tokenIdToMarketItem[_tokenId] = MarketItem({
            tokenId: _tokenId,
            minPrice: _cost,
            uri: _uri,
            seller: payable(msg.sender),
            buyer: payable(address(0)),
            NFTcontract: _nftContract,
            paymentToken: PaymentToken(_paymentToken, _cost),
            bidStartsAt: _bidStartsAt,
            bidEndsAt: _bidEndsAt,
            highestBid: 0,
            isBidActive: true,
            highestBidder: address(0),
            isERC20exits: true,
            isListed: true
        });
    }
}
