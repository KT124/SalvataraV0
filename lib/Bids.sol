// SPDX-License-Identifier: MIT

pragma solidity =0.8.13;

import "../interfaces/IMarket.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Bids {
    function bidInEther(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        mapping(address => mapping(uint256 => Drawable))
            storage drawablesBidder,
        mapping(address => mapping(uint256 => uint256)) storage isBidderOf,
        address _nftContract,
        uint256 _tokenId
    ) external {
        require(
            tokenIdToMarketItem[_tokenId].isListed &&
                tokenIdToMarketItem[_tokenId].isBidActive,
            "Market: Not available."
        );

        require(
            tokenIdToMarketItem[_tokenId].bidEndsAt > block.timestamp,
            "Bid already ended."
        );

        // Can't bid on your own NFT

        require(
            msg.sender != IERC721(_nftContract).ownerOf(_tokenId),
            "Market: owner not allowed!"
        );

        require(
            !tokenIdToMarketItem[_tokenId].isERC20exits,
            "Market: ERC20 token only! "
        );

        if (drawablesBidder[msg.sender][_tokenId].isBidder) {
            // fetching the previous bid amount
            uint256 previousBidAmount = drawablesBidder[msg.sender][_tokenId]
                .eth;

            // calculating the difference to be send with bid

            uint256 differenceBidAmount = tokenIdToMarketItem[_tokenId]
                .highestBid - previousBidAmount;

            // ensuring value sent by the repeat bidder is higher then the difference amount

            require(
                msg.value > differenceBidAmount,
                "Market: must be > the last bid!"
            );

            // new highest bid

            uint256 _newHeighestBid = previousBidAmount + msg.value;

            MarketItem memory _item = tokenIdToMarketItem[_tokenId];

            _item.isBidActive = true;
            _item.highestBid = _newHeighestBid;
            _item.highestBidder = msg.sender;

            /** @dev updating the values of item to storage */
            tokenIdToMarketItem[_tokenId] = _item;

            // drawablesBidder[msg.sender][voucher.tokenId].isBidder = true;
            drawablesBidder[msg.sender][_tokenId].eth = _newHeighestBid;

            drawablesBidder[msg.sender][_tokenId].isBidder = true;

            isBidderOf[msg.sender][_tokenId] = _newHeighestBid;
        } else {
            require(
                msg.value > tokenIdToMarketItem[_tokenId].highestBid &&
                    msg.value >= tokenIdToMarketItem[_tokenId].minPrice,
                "Increase ETH value"
            );

            drawablesBidder[msg.sender][_tokenId].eth = msg.value;

            tokenIdToMarketItem[_tokenId].highestBid = msg.value;
            tokenIdToMarketItem[_tokenId].highestBidder = msg.sender;
            drawablesBidder[msg.sender][_tokenId].isBidder = true;
            tokenIdToMarketItem[_tokenId].isBidActive = true;

            isBidderOf[msg.sender][_tokenId] = msg.value;
        }
    }

    function bidInERC20(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        mapping(address => mapping(uint256 => Drawable))
            storage drawablesBidder,
        mapping(address => mapping(uint256 => uint256))
            storage pendingERC20Withdrawal,
        address _nftContract,
        uint256 _tokenId,
        uint256 _newBidinERC20
    ) external {
        require(
            tokenIdToMarketItem[_tokenId].isListed &&
                tokenIdToMarketItem[_tokenId].isBidActive,
            "Market: not available!"
        );

        require(
            tokenIdToMarketItem[_tokenId].bidEndsAt > block.timestamp,
            "Bid already ended."
        );

        // Can't bid on your own NFT

        require(
            msg.sender != IERC721(_nftContract).ownerOf(_tokenId),
            "Market: owner not allowed!"
        );

        address _paymentToken = tokenIdToMarketItem[_tokenId]
            .paymentToken
            .tokenAddress;

        if (drawablesBidder[msg.sender][_tokenId].isBidder) {
            uint256 _previousBidAmount = drawablesBidder[msg.sender][_tokenId]
                .erc;

            uint256 _differenceBidAmount = tokenIdToMarketItem[_tokenId]
                .highestBid - _previousBidAmount;

            /// below line of code assures a repeat bidder sending the right difference amount

            require(
                _newBidinERC20 > _differenceBidAmount,
                "Market: must be > the last bid!"
            );

            uint256 _newHeighestBid = _previousBidAmount + _newBidinERC20;

            bool _ERC20TransferToMarket = IERC20(_paymentToken).transferFrom(
                msg.sender,
                address(this),
                _newHeighestBid
            );

            require(_ERC20TransferToMarket, "Market: ERC20 TF");

            drawablesBidder[msg.sender][_tokenId].erc = _newHeighestBid;

            drawablesBidder[msg.sender][_tokenId].isBidder = true;

            // pendingWithdrawalsERC20[msg.sender][_token] += _newBidinERC20;

            // below line of  code for restriction in ERC20 withdrawls by bidder

            pendingERC20Withdrawal[msg.sender][_tokenId] = _newHeighestBid;

            tokenIdToMarketItem[_tokenId].highestBidder = msg.sender;

            tokenIdToMarketItem[_tokenId].highestBid = _newHeighestBid;

            tokenIdToMarketItem[_tokenId].isBidActive = true;
        } else {
            // check to ensure bid amount is higher than the last highest bid
            //  if the biddier is the very first bidder, then the bid must be higher than the cost set by the seller in PaymentToken struct //

            require(
                _newBidinERC20 >
                    tokenIdToMarketItem[_tokenId].paymentToken.cost &&
                    _newBidinERC20 > tokenIdToMarketItem[_tokenId].highestBid,
                "Bid higher ERC20"
            );

            drawablesBidder[msg.sender][_tokenId].erc = _newBidinERC20;

            // below line of  code for restriction in ERC20 withdrawls by bidder

            pendingERC20Withdrawal[msg.sender][_tokenId] += _newBidinERC20;

            tokenIdToMarketItem[_tokenId].highestBidder = msg.sender;

            drawablesBidder[msg.sender][_tokenId].isBidder = true;

            tokenIdToMarketItem[_tokenId].highestBid = _newBidinERC20;

            tokenIdToMarketItem[_tokenId].isBidActive = true;
        }

        bool success = IERC20(_paymentToken).transferFrom(
            msg.sender,
            address(this),
            _newBidinERC20
        );

        require(success, "Market: ERC20 TF to market!");
    }
}
