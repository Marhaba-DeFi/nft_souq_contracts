// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC721RFactory is ERC721A, Ownable {
    uint256 public maxMintSupply;
    uint256 public mintPrice;
    uint256 public refundPeriod;

    // Sale Status
    bool public publicSaleActive;
    bool public presaleActive;
    uint256 public refundEndTime;

    address public refundAddress;
    // address public refundERC20;
    uint256 public maxUserMintAmount;
    bool public whitelistEnabled = false;

    mapping(address => bool) public whitelist;

    mapping(uint256 => bool) public hasRefunded; // users can search if the NFT has been refunded
    mapping(uint256 => bool) public isOwnerMint; // if the NFT was freely minted by owner

    string private baseURI;

    constructor(
        string memory name, 
        string memory symbol,
        uint mintSupply, 
        uint256 mintingPrice, 
        uint256 refundTime, 
        uint maxMintPerUser 
    ) ERC721A(name, symbol) {
        bytes memory validateName = bytes(name); // Uses memory
        bytes memory validateSymbol = bytes(symbol);
        require( validateName.length != 0 && validateSymbol.length != 0, "ERC721R: Choose a name and symbol");
        refundAddress = msg.sender;
        maxMintSupply = mintSupply;
        mintPrice = mintingPrice;
        refundPeriod = refundTime;
        maxUserMintAmount = maxMintPerUser;
        toggleRefundCountdown();
    }

    function preSaleMint(uint256 quantity)
        external
        payable
    {
        require(presaleActive, "Presale is not active");
        require(msg.value == quantity * mintPrice, "Value");
        if(whitelistEnabled == true) {
            require(whitelist[_msgSender()], "Address not whitelisted");
        }
        require(
            _numberMinted(msg.sender) + quantity <= maxUserMintAmount,
            "Max amount"
        );
        require(_totalMinted() + quantity <= maxMintSupply, "Max mint supply");

        _safeMint(msg.sender, quantity);
    }

    function publicSaleMint(uint256 quantity) external payable {
        require(publicSaleActive, "Public sale is not active");
        require(msg.value >= quantity * mintPrice, "Not enough eth sent");
        require(
            _numberMinted(msg.sender) + quantity <= maxUserMintAmount,
            "Over mint limit"
        );
        require(
            _totalMinted() + quantity <= maxMintSupply,
            "Max mint supply reached"
        );

        _safeMint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity) external onlyOwner {
        require(
            _totalMinted() + quantity <= maxMintSupply,
            "Max mint supply reached"
        );
        _safeMint(msg.sender, quantity);

        for (uint256 i = _currentIndex - quantity; i < _currentIndex; i++) {
            isOwnerMint[i] = true;
        }
    }

    function refund(uint256[] calldata tokenIds) external {
        require(isRefundGuaranteeActive(), "Refund expired");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "Not token owner");
            require(!hasRefunded[tokenId], "Already refunded");
            require(!isOwnerMint[tokenId], "Freely minted NFTs cannot be refunded");
            hasRefunded[tokenId] = true;
            transferFrom(msg.sender, refundAddress, tokenId);
        }

        uint256 refundAmount = tokenIds.length * mintPrice;
        (bool os, ) = payable(msg.sender).call{value: refundAmount}("");
        require(os);
    }

    function getRefundGuaranteeEndTime() public view returns (uint256) {
        return refundEndTime;
    }

    function isRefundGuaranteeActive() public view returns (bool) {
        return (block.timestamp <= refundEndTime);
    }

    function withdraw() external onlyOwner {
        require(block.timestamp > refundEndTime, "Refund period not over");
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setRefundAddress(address _refundAddress) external onlyOwner {
        refundAddress = _refundAddress;
    }

    
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function toggleRefundCountdown() public onlyOwner {
        refundEndTime = block.timestamp + refundPeriod;
    }

    function togglePresaleStatus() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function togglePublicSaleStatus() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function setWhitelistEnabled(bool _state) public onlyOwner {
        whitelistEnabled = _state;
    }

    function setWhitelist(address[] calldata newAddresses) public onlyOwner {
        // At least one royaltyReceiver is required.
        require(newAddresses.length > 0, "No user details provided");
        // Check on the maximum size over which the for loop will run over.
        require(newAddresses.length <= 5, "Too many userss to whitelist");
        for (uint256 i = 0; i < newAddresses.length; i++)
            whitelist[newAddresses[i]] = true;
    }

    function removeWhitelist(address[] calldata currentAddresses) public onlyOwner {
        // At least one royaltyReceiver is required.
        require(currentAddresses.length > 0, "No user details provided");
        // Check on the maximum size over which the for loop will run over.
        require(currentAddresses.length <= 5, "Too many userss to whitelist");
        for (uint256 i = 0; i < currentAddresses.length; i++)
            delete whitelist[currentAddresses[i]];
    }
}