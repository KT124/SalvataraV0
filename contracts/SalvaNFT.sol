// SPDX-License-Identifier: GPL-3.0

/**
 @notice an NFT contract to mint royalty and non-royalty NfTs
 @dev provides functionality to mint with roayalty and without roaylty .

 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/interfaces/IERC2981.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SalvaNFT is
    ReentrancyGuard,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Holder,
    ERC721Royalty,
    Pausable,
    AccessControl
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct RoyaltyReceiver {
        address payable creator;
        uint256 royaltyInBP;
    }

    event PaymentReceived(address indexed sender, uint256 indexed value);

    // to track nft id to its royalty receiver
    mapping(uint256 => RoyaltyReceiver) public royalties;

    // mapping(uint256 => MarketItem) private idToMarketItem;

    mapping(bytes32 => bool) private uriExits;

    mapping(uint256 => bytes32) private tokenIdToHash;

    /**  @dev default royalty recipient */
    address public _recipient;

    /** @dev MarketPlace address to be set lalter. This allows this contract to set 'approval' for  all natively minted NFTs in the 'mint' function */

    address public Market;

    /** @dev maximum supply of token that can be mited into existence at any given time */
    // uint256 public constant MAX_SUPPLY = 10;

    /** @dev default royalty '_recipient' is deployer. This is overwrittent everytime safeMint is called and _recipient to set to _msgSender() */

    constructor() ERC721("Salvatara Art", "START") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _recipient = _msgSender();
    }

    /** @dev 'to' nft receiver
     *  @dev 'uri' for nft
     *  @dev '_royaltyPerecet' to be set by the minter
     *  @dev '_royaltyToken:' ERC20 currency address
     */

    function mintNFTWithRoyalty(
        // address to,
        string memory uri,
        uint256 _royaltyInBP // in basis points: 1%=100 basis points
    )
        public
        payable
        whenNotPaused
        onlyRole(MINTER_ROLE)
        nonReentrant
        returns (uint256)
    {
        require(msg.sender != address(0), "START: invalid address!");

        // require(totalSupply() < MAX_SUPPLY, "max supply reached.");

        uint256 tokenId = mintNFT(uri);

        // _tokenIdCounter.increment();
        // uint256 tokenId = _tokenIdCounter.current();
        // _tokenIdCounter.increment();
        require(
            (_royaltyInBP) <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );

        royalties[tokenId] = RoyaltyReceiver({
            creator: payable(_msgSender()),
            royaltyInBP: _royaltyInBP
        });

        /** Input royalty from frontend is precent. So to convert the royalty(in percet) in Basis points, multiply by 100*/
        // _setRoyalties(_msgSender(), (_royaltyPercent * 100));

        //mints nft to msg.sender
        // _safeMint(_msgSender(), tokenId);
        // _setTokenURI(tokenId, uri);
        // setApprovalForAll(address(this), true);
        // setApprovalForAll(Market, true);
        // require(isApprovedForAll(_msgSender(), address(this)));

        return tokenId;
    }

    /** @dev mint without royallty */
    /** @notice mints to user  an nft without royalty */
    /** @param  _uri the unique IPFS hash of the NFT item */
    /** @notice returns unique NFT id */

    function mintNFT(string memory _uri)
        public
        whenNotPaused
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        bytes32 _uriHash = _hash(_uri);
        require(!uriExits[_uriHash], "uri already minted!");

        uriExits[_uriHash] = true;

        unchecked {
            _tokenIdCounter.increment();
        }
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(_msgSender(), tokenId);
        _setTokenURI(tokenId, _uri);
        setApprovalForAll(address(this), true);
        setApprovalForAll(Market, true);
        require(isApprovedForAll(_msgSender(), address(this)));
        tokenIdToHash[tokenId] = _uriHash;

        unchecked {
            _tokenIdCounter.increment();
        }

        return tokenId;
    }

    function _hash(string memory _uri) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_uri));
    }

    /** @notice to pause the contract mint, burn and withdraw functionality in Emergency */

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /** @dev EIP2981 royalties implementation. */
    /** @dev sets to royatly recipient and  amount */
    /** @dev Internally called by mintWithRoyaltyFuction at the time of mint. Amount is Percent and Not Basis Percent. */

    // function _setRoyalties(address royaltyRecipient, uint256 _royaltyPercent)
    //     private
    // {
    //     require(
    //         royaltyRecipient != address(0),
    //         "Royalties: new recipient is the zero address"
    //     );
    //     require(_royaltyPercent > 0, "Royalty can not be zero");
    //     _recipient = royaltyRecipient;
    // }

    /** @notice EIP2981 standard royalties returns royalty receiver address and royalty amount to be sent */

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 percent = royalties[_tokenId].royaltyInBP;
        // address _receiver = royalties[_tokenId].creator;

        return (
            royalties[_tokenId].creator,
            (percent * _salePrice) / _feeDenominator()
        );
    }

    /** @notice To set the market address so that it can be approved for all at the  time of minting before market listing */

    function setMarketAddress(address _market)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(isContract(_market), "invalid contract address.");

        Market = _market;
    }

    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /** @dev called by other contracts to check if this contracts supports certain ABI before other contract can call this contract*/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC721Royalty, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** The following functions are overrides required by Solidity. */

    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     uint256 batchSize
    // ) internal override(ERC721Enumerable) whenNotPaused {
    //     super._beforeTokenTransfer(from, to, tokenId);
    // }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function burn(uint256 _tokenId) external whenNotPaused {
        require(msg.sender == ownerOf(_tokenId), "Only owner!");
        bytes32 _uriHash = tokenIdToHash[_tokenId];
        delete uriExits[_uriHash];
        delete tokenIdToHash[_tokenId];

        _burn(_tokenId);
    }

    function _burn(uint256 _tokenId)
        internal
        override(ERC721, ERC721URIStorage, ERC721Royalty)
    {
        super._burn(_tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /** @dev  To handle the receipt and withdrawl of Ether to and from this contract */

    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /** @dev Function to receive ether, msg.data is not empty */
    fallback() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /** @notice returns the ETH balance of this contract */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /** @notice to withdraw Ether sent to this contract */
    /** @param  to_ is the receiver of the fund.*/
    /** @param  val_ is the value to be withdrawn  */
    function withdraw(uint256 val_)
        public
        payable
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
        nonReentrant
    {
        require(msg.sender != address(0), "can't send to zero address!");
        require(val_ > 0, "can't send zero value!");
        bool success = payable(msg.sender).send(val_);

        require(success, "send failed");
    }
}
