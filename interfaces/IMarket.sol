//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

struct MarketItem {
    uint256 tokenId;
    uint256 minPrice;
    string uri;
    address payable seller;
    address payable buyer;
    address NFTcontract;
    PaymentToken paymentToken;
    uint256 bidStartsAt;
    uint256 bidEndsAt;
    uint256 highestBid;
    bool isBidActive;
    address highestBidder;
    bool isERC20exits;
    bool isListed;
}
struct PaymentToken {
    address tokenAddress;
    uint256 cost;
}

struct Drawable {
    uint256 eth;
    uint256 erc;
    bool isBidder;
    bool isSeller;
}

struct Bid {
    uint256 bidStartsAt;
    uint256 bidEndsAt;
    uint256 highestBid;
    bool isBidActive;
    bool bidSuccess;
    bool bidInit;
    address[] bidders;
    address paymentToken;
}

interface IMarket {
    event MarketItemCreated(
        address indexed creator,
        uint256 indexed tokenId,
        uint256 indexed minPrice
    );

    event MarketItemCancelled(
        address indexed cancelledBy,
        uint256 indexed tokenId
    );

    event MarketItemSold(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 sellPrice
    );

    event BidMade(
        address indexed Bidder,
        uint256 indexed BidAmount,
        uint256 indexed tokenId
    );

    event ERC20withdrawal(
        address indexed receiever,
        uint256 indexed amount,
        address indexed _ERC20token
    );
    event Etherwithdrawal(address indexed receiver, uint256 indexed value);
    event EtherReceived(address indexed sender, uint256 indexed value);
    event ListingFeeModified(uint256 fee);
}
