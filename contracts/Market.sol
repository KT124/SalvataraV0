//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "../interfaces/IMarket.sol";
import {LibMarket} from "../lib/LibMarket.sol";
import {Bids} from "../lib/Bids.sol";
import {CreateItem} from "../lib/CreateItem.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Market is
    IMarket,
    ReentrancyGuard,
    Pausable,
    ERC721Holder,
    AccessControl
{
    // using SafeERC20 for IERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public constant MARKET_NAME = "Salvatara NFT Market-Place";

    IERC721 public nftContract;

    using LibMarket for *;
    using Bids for *;

    uint256 public listingFee;
    uint256 public TotalplatformFeeInEth;
    uint256 public TotalplatformFeeInERC20;

    /** @dev used to keep track of bidders eth amount bid on each token Id so that he can withdraw it after bid */

    mapping(address => mapping(uint256 => uint256)) isBidderOf;
    mapping(address => mapping(uint256 => uint256)) pendingERC20Withdrawal;

    // // to keep track of Market item with an unique index

    mapping(address => mapping(uint256 => Drawable)) drawablesBidder;
    // mapping(address => Drawable) drawablesBidder;
    mapping(address => Drawable) drawableSeller;
    //keep track of all ERC20 sent by each bidder.
    mapping(address => uint256) pendingERC20Withdrawals;

    // to keep track of all marketitems created with unique on-chain NFT id.

    mapping(uint256 => MarketItem) public tokenIdToMarketItem;

    mapping(uint256 => address) public tokenIdToNFTcontract;

    constructor(address _nftContract) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        require(isContract(_nftContract), "invalid address.");

        nftContract = IERC721(_nftContract);
    }

    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /** @dev functionos to pause contract functionality */

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unPause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /** The following functions is override required by Solidity. */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function createMarketItemWithEtherPrice(
        uint256 _tokenId,
        uint256 _price,
        string memory _uri,
        uint256 _bidStartsAt,
        uint256 _bidEndsAt,
        address _nftContract
    ) public payable whenNotPaused {
        require(
            (IERC721(_nftContract).ownerOf(_tokenId) == msg.sender),
            "Market: Only-NFT-owner"
        );

        // string memory URI = ERC721(_nftContract).tokenURI(_tokenId);

        // require(_uri == URI, "Market: URI mismatch!");

        require(!tokenIdToMarketItem[_tokenId].isListed, "already listed!");

        require(msg.sender != address(0), "Invalid address!");

        require(msg.value >= listingFee, "listing fee required.");

       // ensuring tokenURI privided here matches the uri of tokenId provded

        require(
            (bytes(_uri).length ==
                bytes(ERC721(_nftContract).tokenURI(_tokenId)).length),
            "Market: URI lenght mismatch!"
        );
        require(
            keccak256(abi.encodePacked(_uri)) ==
                keccak256(
                    abi.encodePacked(ERC721(_nftContract).tokenURI(_tokenId))
                ),
            "Market: URI mismatch!"
        );

        TotalplatformFeeInEth += msg.value;
        CreateItem.createMarketItemWithEtherPrice(
            tokenIdToMarketItem,
            _tokenId,
            _price,
            _uri,
            _bidStartsAt,
            _bidEndsAt,
            _nftContract
        );

        // tokenIdToMarketItem[_tokenId] = MarketItem({
        //     tokenId: _tokenId,
        //     minPrice: _price,
        //     uri: _uri,
        //     seller: payable(_msgSender()),
        //     buyer: payable(address(0)),
        //     NFTcontract: _nftContract,
        //     paymentToken: PaymentToken(address(0), 0),
        //     bidStartsAt: _bidStartsAt,
        //     bidEndsAt: _bidEndsAt,
        //     highestBid: 0,
        //     isBidActive: true,
        //     bidders: new address[](0),
        //     isERC20exits: false,
        //     isListed: true
        // });

        drawableSeller[msg.sender].isSeller = true;
        tokenIdToNFTcontract[_tokenId] = _nftContract;

        emit MarketItemCreated(msg.sender, _tokenId, _price);
    }

    function createMarketItemWithERC20tokenPrice(
        address _paymentToken,
        address _nftContract,
        uint256 _tokenId,
        uint256 _cost,
        string memory _uri,
        uint256 _bidStartsAt,
        uint256 _bidEndsAt
    ) public payable whenNotPaused {
        require(msg.sender != address(0), "zero address!");
        require(
            (IERC721(_nftContract).ownerOf(_tokenId) == msg.sender),
            "Only NFT-owner"
        );

        require(!tokenIdToMarketItem[_tokenId].isListed, "already listed!");

        if (listingFee > 0) {
            require(msg.value >= listingFee, "listing fee required.");

            TotalplatformFeeInEth += msg.value;
        }

        require(isContract(_paymentToken), "Market: invalid ERC20 contract!");
        require(isContract(_nftContract), "Market: invalid ERC721 contract!");
        // require(_bidEndsAt < 91 days, "Market: keep bid duration < 91 days!");

        // tokenIdToMarketItem[_tokenId] = MarketItem({
        //     tokenId: _tokenId,
        //     minPrice: _cost,
        //     buyNowPrice: _buyNowPrice,
        //     uri: _uri,
        //     seller: payable(_msgSender()),
        //     buyer: payable(address(0)),
        //     NFTcontract: _nftContract,
        //     paymentToken: PaymentToken(_paymentToken, _cost),
        //     bidStartsAt: _bidStartsAt,
        //     bidEndsAt: _bidEndsAt,
        //     highestBid: 0,
        //     isBidActive: true,
        //     bidders: new address[](0),
        //     isERC20exits: true,
        //     isListed: true
        // });

        CreateItem.createMarketItemWithERC20tokenPrice(
            tokenIdToMarketItem,
            _paymentToken,
            _nftContract,
            _tokenId,
            _cost,
            _uri,
            _bidStartsAt,
            _bidEndsAt
        );

        drawableSeller[msg.sender].isSeller = true;

        tokenIdToNFTcontract[_tokenId] = _nftContract;

        emit MarketItemCreated(msg.sender, _tokenId, _cost);
    }

    /// @notice To start a Bid for an nft

    // function makeAbid(
    //     address _nftContract,
    //     uint256 _tokenId,
    //     uint256 _newBidinERC20
    // ) public payable whenNotPaused nonReentrant {
    //     // bidExits[_tokenId] = true;

    //     require(msg.sender != address(0), "Invalid address");
    //     MarketItem memory item = tokenIdToMarketItem[_tokenId];

    //     require(item.isListed && item.isBidActive, "Market: not available!");

    //     require(item.bidEndsAt > block.timestamp, "Market: bid already ended!");

    //     // Can't bid on your own NFT

    //     require(
    //         _msgSender() != IERC721(_nftContract).ownerOf(_tokenId),
    //         "Market: owner not allowed!"
    //     );

    //     if (msg.value != 0) {
    //         require(!item.isERC20exits, "Market: ERC20 token only! ");

    //         require(
    //             msg.value > item.highestBid && msg.value >= item.minPrice,
    //             "Increase ETH value"
    //         );
    //         emit BidMade(msg.sender, msg.value, _tokenId);

    //         drawablesBidder[msg.sender].eth += msg.value;

    //         tokenIdToMarketItem[_tokenId].highestBid = msg.value;
    //         isBidderOf[msg.sender][_tokenId] += msg.value;

    //         tokenIdToMarketItem[_tokenId].bidders.push(msg.sender);
    //         drawablesBidder[msg.sender].isBidder = true;
    //         tokenIdToMarketItem[_tokenId].isBidActive = true;
    //     } else {
    //         require(item.isERC20exits);

    //         // check to ensure bid amount is higher than the last highest bid
    //         //  if the biddier is the very first bidder, then the bid must be higher than the cost set by the seller in PaymentToken struct //

    //         require(
    //             _newBidinERC20 > item.paymentToken.cost &&
    //                 _newBidinERC20 > item.highestBid,
    //             "Bid higher ERC20"
    //         );

    //         emit BidMade(msg.sender, _newBidinERC20, _tokenId);

    //         // Transferring ERC20 to marketpalce. Market must be approved by the  bidder to transfer ERC20

    //         address _token = tokenIdToMarketItem[_tokenId]
    //             .paymentToken
    //             .tokenAddress;

    //         drawablesBidder[msg.sender].erc += _newBidinERC20;
    //         // pendingWithdrawalsERC20[msg.sender][_token] += _newBidinERC20;

    //         // below line of  code for restriction in ERC20 withdrawls by bidder

    //         pendingERC20Withdrawal[msg.sender][_tokenId] += _newBidinERC20;

    //         tokenIdToMarketItem[_tokenId].bidders.push(msg.sender);

    //         drawablesBidder[msg.sender].isBidder = true;

    //         tokenIdToMarketItem[_tokenId].highestBid = _newBidinERC20;

    //         tokenIdToMarketItem[_tokenId].isBidActive = true;

    //         // LibMarket.safeTransferFrom(
    //         //     IERC20(_token),
    //         //     msg.sender,
    //         //     address(this),
    //         //     _newBidinERC20
    //         // );

    //         bool success = IERC20(_token).transferFrom(
    //             msg.sender,
    //             address(this),
    //             _newBidinERC20
    //         );

    //         require(success, "Market: ERC20 TF");
    //     }
    // }

    function bidwithEther(address _nftContract, uint256 _tokenId)
        external
        payable
    {
        emit BidMade(msg.sender, msg.value, _tokenId);
        Bids.bidInEther(
            tokenIdToMarketItem,
            drawablesBidder,
            isBidderOf,
            _nftContract,
            _tokenId
        );
    }

    function bidWithERC(
        address _nftContract,
        uint256 _tokenId,
        uint256 _newBidinERC20
    ) external {
        emit BidMade(msg.sender, _newBidinERC20, _tokenId);
        Bids.bidInERC20(
            tokenIdToMarketItem,
            drawablesBidder,
            pendingERC20Withdrawal,
            _nftContract,
            _tokenId,
            _newBidinERC20
        );
    }

    function acceptBid(IERC721 _nftContract, uint256 _tokenId)
        public
        whenNotPaused
        nonReentrant
    {
        /**@dev ---Sanity check------------------- */
        require(
            (IERC721(_nftContract).ownerOf(_tokenId) == msg.sender) ||
                tokenIdToMarketItem[_tokenId].highestBidder == msg.sender,
            "Only NFT-owner or highest bidder!"
        );
        require(drawableSeller[msg.sender].isSeller, "Market: Only sellers.");
        require(
            tokenIdToMarketItem[_tokenId].isListed &&
                tokenIdToMarketItem[_tokenId].isBidActive,
            "Market: id not listed or no bid on it"
        );
        address payable seller = payable(msg.sender);
        require(seller != address(0), "caller zero address.");

        address highestBidder = tokenIdToMarketItem[_tokenId].highestBidder;

        uint256 amount = tokenIdToMarketItem[_tokenId].highestBid;

        /**@dev end of sanit check------------------- */

        /** @dev tranfer of value and assets starts */

        if (tokenIdToMarketItem[_tokenId].isERC20exits) {
            /**-------------------------------------------------------------*/

            // USING "ERC20AndAssetTransfer"LIBRARY TO PERFORM THE TRANSFER FUNCTIONS
            tokenIdToMarketItem.ERC20AndAssetTransfer(
                drawablesBidder,
                _tokenId
            );

            /**------------------------------------------------------------*/

            // uint256 amount = tokenIdToMarketItem[_tokenId].highestBid;

            emit MarketItemSold(seller, highestBidder, _tokenId, amount);

            delete tokenIdToMarketItem[_tokenId];
        } else {
            // storing  highest bid into 'amount' of Eth to send it to seller
            // uint256 amount = tokenIdToMarketItem[_tokenId].highestBid;

            emit MarketItemSold(seller, highestBidder, _tokenId, amount);

            /**-------------------------------------------------------------*/

            // USING "ERC20AndAssetTransfer"LIBRARY TO PERFORM THE TRANSFER FUNCTIONS

            tokenIdToMarketItem.EThAndAssetTransfer(drawablesBidder, _tokenId);

            /**-------------------------------------------------------------*/

            delete tokenIdToMarketItem[_tokenId];
        }
    }

    /** ---------------------------@dev trnasfer the NFT to highets bidder------------------------------*/

    //******* USING _transferAsset() FUNCTION IN LIBTRAY**************//

    /**-------------------------@dev asset transfer complete------------------------------------------ */

    function setListingFee(uint256 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit ListingFeeModified(_fee);
        listingFee = _fee;
    }

    // /** @dev ---------------------------------Functions to withdraw Ether or ERC20 to cretor/seller account ----------------------------------- */

    // /// @notice Transfers all pending withdrawal balance to the caller. Reverts if the caller is not an authorized minter.

    function withdrawEther(uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        require(
            block.timestamp > tokenIdToMarketItem[_tokenId].bidEndsAt,
            "Only after bid duration!"
        );

        
        require(
            msg.sender != tokenIdToMarketItem[_tokenId].highestBidder,
            "Market: highest bidder not allowed!"
        );
        require(
            isBidderOf[msg.sender][_tokenId] > 0,
            "Market: no pending widrawls for this Id"
        );

        require(
            drawablesBidder[msg.sender][_tokenId].isBidder ||
                drawableSeller[msg.sender].isSeller,
            "Only bidders or authorized minters"
        );

        address payable receiver = payable(msg.sender);
        require(receiver != address(0));
        uint256 amount;

        if (drawablesBidder[msg.sender][_tokenId].isBidder) {
            amount = drawablesBidder[receiver][_tokenId].eth;
            require(amount != 0, "Zero Eth Bal.");

            // zero account before transfer to prevent re-entrancy attack

            delete drawablesBidder[receiver][_tokenId].eth;
        } else {
            amount = drawableSeller[receiver].eth;

            require(amount != 0, "Zero Eth Bal.");

            // zero account before transfer to prevent re-entrancy attack
            delete drawableSeller[receiver].eth;
        }

        /// @dev Emitting Etherwithdrawal event before state change to  Ether balance of caller
        emit Etherwithdrawal(receiver, amount);

        // USING LIBTRANSFER TO  ACCOMPLISH THE BELOW ETH TRANSFER

        LibMarket.transferEth(receiver, amount);
    }

    function withdrawERC20(address _ERC20token, uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        require(msg.sender != address(0), "Invalid caller");
        require(
            block.timestamp > tokenIdToMarketItem[_tokenId].bidEndsAt,
            "Only after bid duration!"
        );

        require(
            drawablesBidder[msg.sender][_tokenId].isBidder ||
                drawableSeller[msg.sender].isSeller,
            "Only bidders or sellers."
        );

        require(
            pendingERC20Withdrawal[msg.sender][_tokenId] > 0,
            "Zero ER20 balance!"
        );

        uint256 amount = drawablesBidder[msg.sender][_tokenId].erc;

        require(amount != 0, "Zero ERC20 balance!");

        /// @dev Emitting ERC20withdrawal before state changes to ERC20 balance of caller
        emit ERC20withdrawal(msg.sender, amount, _ERC20token);

        // CHANGED TO FOLLOWING AS AVAILABLE TO WITHDRAW WAS NOT UPDATING AFTER TRASFER SUCCESSFUL TRANSFER
        bool sent = drawablesBidder.transferERC20(_ERC20token, _tokenId);

        require(sent, "ERC20 TF");
    }

    /// @notice Retuns the amount of Ether available to the caller to withdraw.
    function availableToWithdrawSeller()
        public
        view
        returns (uint256 ethAmount, uint256 ercAmount)
    {
        return (drawableSeller[msg.sender].eth, drawableSeller[msg.sender].erc);
    }

    /// @notice Retuns the amount of Ether available to the caller to withdraw.

    function availableToWithdrawBidder(uint256 _tokenId)
        public
        view
        returns (uint256 ethAmount, uint256 erc20Amount)
    {
        return (
            drawablesBidder[msg.sender][_tokenId].eth,
            drawablesBidder[msg.sender][_tokenId].erc
        );
    }

    // /** ---------------------------------------------------Withdraw fuctions end here----------------------------------------------------------- */

    // /** ----------------------------To Withdraw bid -------------------------------------- */

    function revokeMarketItem(uint256 _tokenId) public whenNotPaused {
        MarketItem memory item = tokenIdToMarketItem[_tokenId];
        address _nftContract = item.NFTcontract;

        require(
            msg.sender == IERC721(_nftContract).ownerOf(_tokenId),
            "Market: Only NFT owner."
        );

        emit MarketItemCancelled(msg.sender, _tokenId);

        delete tokenIdToMarketItem[_tokenId];
    }

    /** @dev Required for any contract which needs to receive Ehter value */

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    function withDrawMarketFeeEth(address payable receiver)
        external
        payable
        whenNotPaused
        nonReentrant
        returns (bool sent)
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Admin allowed");
        require(receiver != address(0), "Market: zero adddress");

        uint256 amount = TotalplatformFeeInEth;
        TotalplatformFeeInEth = 0;

        (sent, ) = receiver.call{value: amount}("");
        require(sent, "withdrawal failed");
    }

    function updateNFTContractAddress(address _newAddress) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Admin allowed");

        require(isContract(_newAddress), "Market: invalid address");
        nftContract = IERC721(_newAddress);
    }

    /** @dev The following function of ERC721Holder is implemented so as to enable the INF contract to receive ERC721 tokens  */

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
