// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "../interfaces/IMarket.sol";

library LibMarket {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    using SafeERC20 for IERC20;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) external {
        token.safeTransfer(to, amount);
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) external {
        token.safeTransferFrom(from, to, amount);
    }

    function transferNFT(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        IERC721 nft,
        uint256 id
    ) external {
        address highestBidder = tokenIdToMarketItem[id].highestBidder;
        address seller = tokenIdToMarketItem[id].seller;

        nft.transferFrom(seller, highestBidder, id);
    }

    function ERC20AndAssetTransfer(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        mapping(address => mapping(uint256 => Drawable))
            storage drawablesBidder,
        uint256 _tokenId
    ) external {
        require(tokenIdToMarketItem[_tokenId].isERC20exits);
        uint256 amount = tokenIdToMarketItem[_tokenId].highestBid;
        address nftContract = (tokenIdToMarketItem[_tokenId].NFTcontract);
        // ISalvaNFT _nftContract = ISalvaNFT(nftContract);

        address erc20Token = tokenIdToMarketItem[_tokenId]
            .paymentToken
            .tokenAddress;

        address payable seller = payable(msg.sender);
        require(seller != address(0), "caller zero address.");

        address highestBidder = tokenIdToMarketItem[_tokenId].highestBidder;

        // emit MarketItemSold(seller, highestBidder, _tokenId, amount);

        if (!_checkRoyalties(nftContract)) {
            //  IF SAFE TRASNFER FROM DOES NOT WORK NEED TO CHECK ONLY TRANSFER
            IERC20(erc20Token).safeTransfer(seller, amount);

            //deducting withdrawable ERC20 balance 'amount' from highest bidder

            delete drawablesBidder[highestBidder][_tokenId].erc;

            //transfer asset

            _transferAsset(tokenIdToMarketItem, IERC721(nftContract), _tokenId);

            return;
        }

        (address royaltyRecipient, uint256 royaltyAmount) = IERC2981(
            nftContract
        ).royaltyInfo(_tokenId, amount);

        if (royaltyRecipient == seller) {
            bool success1 = IERC20(erc20Token).transfer(seller, amount);
            require(success1, "IERC20: TF");

            //deducting withdrawable ERC20 balance 'amount' from highest bidder

            delete drawablesBidder[highestBidder][_tokenId].erc;

            //transfer asset

            _transferAsset(tokenIdToMarketItem, IERC721(nftContract), _tokenId);
        } else {
            // transfer value. Deducting royalty before transfer of ERC20

            bool success2 = IERC20(erc20Token).transfer(
                seller,
                (amount - royaltyAmount)
            );
            require(success2, "IERC20: TF");

            // sending royalty to creator

            bool success1 = IERC20(erc20Token).transfer(
                royaltyRecipient,
                royaltyAmount
            );
            require(success1, "IERC20: TF");

            //deleting withdrawable ERC20 balance 'amount' from highest bidder mapping

            delete drawablesBidder[highestBidder][_tokenId].erc;

            //transfer asset

            _transferAsset(tokenIdToMarketItem, IERC721(nftContract), _tokenId);
        }

        // to reset all value to zero for the token-Id sold
    }

    function EThAndAssetTransfer(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        mapping(address => mapping(uint256 => Drawable))
            storage drawablesBidder,
        uint256 _tokenId
    ) external {
        uint256 amount = tokenIdToMarketItem[_tokenId].highestBid;
        address nftContract = tokenIdToMarketItem[_tokenId].NFTcontract;
        // ISalvaNFT _nftContract = ISalvaNFT(nftContract);

        address payable seller = payable(msg.sender);
        require(seller != address(0), "caller zero address.");

        address highestBidder = tokenIdToMarketItem[_tokenId].highestBidder;

        // market is calling to nft contract to check if nft contracts does not impletment royalties

        if (!_checkRoyalties(nftContract)) {
            (bool success, ) = seller.call{value: amount}("");

            require(success, "Market: Ether TF");

            //deleting withdrawable Eth balance 'amount' from highest bidder mapping
            delete drawablesBidder[highestBidder][_tokenId].eth;

            // transeferring NFT to highest bidder

            _transferAsset(tokenIdToMarketItem, IERC721(nftContract), _tokenId);

            return;
        }

        (address royaltyRecipient, uint256 royaltyAmount) = IERC2981(
            nftContract
        ).royaltyInfo(_tokenId, amount);
        // (address royaltyRecipient, uint256 royaltyAmount) = ERC721Royalty(
        //     nftContract
        // ).royaltyInfo(_tokenId, amount);

        if (royaltyRecipient == msg.sender) {
            (bool success1, ) = seller.call{value: amount}("");

            require(success1, "Market: Ether TF");

            //deleting withdrawable Eth balance 'amount' from highest bidder
            delete drawablesBidder[highestBidder][_tokenId].eth;

            // transeferring NFT to highest bidder

            _transferAsset(tokenIdToMarketItem, IERC721(nftContract), _tokenId);
        } else {
            // sending roaylty to creator

            (bool success2, ) = payable(royaltyRecipient).call{
                value: royaltyAmount
            }("");
            require(success2, "Market: Ether TF");

            // sending the Eth to seller after deducting royaltyAmount

            (bool success3, ) = seller.call{value: (amount - royaltyAmount)}(
                ""
            );

            require(success3, "Market: Ether TF");

            //deducting withdrawable Eth balance 'amount' from highest bidder
            drawablesBidder[highestBidder][_tokenId].eth;

            // transeferring NFT to highest bidder

            _transferAsset(tokenIdToMarketItem, IERC721(nftContract), _tokenId);
        }

        // to reset all value to zero for the token Id sole
    }

    function _transferAsset(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        IERC721 _nft,
        uint256 _tokenId
    ) private {
        address highestBidder = tokenIdToMarketItem[_tokenId].highestBidder;

        address seller = tokenIdToMarketItem[_tokenId].seller;

        _nft.transferFrom(seller, highestBidder, _tokenId);
    }

    // USED ONLY for withdraw function to  allow not-successful bids to be withdrawn by the respective bidders
    function transferERC20(
        mapping(address => mapping(uint256 => Drawable))
            storage drawablesBidder,
        address _ERC20token,
        uint256 _tokenId
    ) external returns (bool) {
        address payable receiver = payable(msg.sender);

        require(receiver != address(0), "Market: invalid address");
        uint256 amount = drawablesBidder[msg.sender][_tokenId].erc;

        ///  make state changes before transferring ERC20 token
        drawablesBidder[msg.sender][_tokenId].erc -= amount;

        bool success = IERC20(_ERC20token).transfer(receiver, amount);

        require(success, "Market: ERC20 TF.");

        return success;
    }

    // used externally by library to check if IERC2981 is implemented by target contract
    function _checkRoyalties(address _contract) private view returns (bool) {
        bool success = IERC2981(_contract).supportsInterface(
            _INTERFACE_ID_ERC2981
        );
        return success;
    }

    // for normal Eth value transfer. Can be used anywhere

    function transferEth(address to, uint256 amount) external {
        (bool success, ) = to.call{value: amount}("");
        require(success, "ETH: TF");
    }
}
