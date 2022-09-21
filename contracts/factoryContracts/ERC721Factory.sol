// SPDX-License-Identifier: MIT
/**
 * ERC721FactoryFacet is used to mint NFTs that are ERC721 compliant.
 * The mint function can only be called from souq Media contract.
 * It is initialized with name and symbol and default royalty.
 *
 */

pragma solidity ^0.8.6;

import "../ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ERC721 factory contract
 * @dev This contract inherits from ERC721 openzeppelin contract, openzeppelin ERC721Enumerable,
 * pausable, ERC721URIStorage and ERC2981 royalty contracts.
 */
contract ERC721Factory is ERC721, ERC721Enumerable, ERC2981, Ownable {
    using Strings for uint256;
    string public uriSuffix = ".json";
    string public baseURI = "";
    uint256 mapSize = 0; //Keeps a count of white listed users. Max is 2000

    bool public whitelistEnabled = false;

    // Mapping from token ID to creator address
    mapping(uint256 => address) public _creators;
    mapping(address => bool) public whitelist; //Addresses that are whitelisted

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    /**
     * @dev Emitted when `WhiteListEnabled` is toggled.
     */
    event WhiteListEnabled(bool whitelistEnabled);

    /**
     * @dev Emitted when `BaseURI` is set.
     */
    event BaseURI(string uri);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` and default royalty to the token collection.
     * @notice default royalty is optional. DefaultRoyalty is set, if the flag is true.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        bool defaultRoyalty,
        address[] memory royaltyReceiver,
        uint96[] memory royaltyFeesInBips
    ) ERC721(_name, _symbol) {
        bytes memory name = bytes(_name); // Uses memory
        bytes memory symbol = bytes(_symbol);
        require(name.length != 0 && symbol.length != 0, "ERC721: Choose a name and symbol");
        if (defaultRoyalty) {
            _setDefaultRoyalty(royaltyReceiver, royaltyFeesInBips);
        }
    }

    function setWhitelistEnabled(bool _state) public onlyOwner {
        whitelistEnabled = _state;

        emit WhiteListEnabled(whitelistEnabled);
    }

    /**
     * @dev set whitelisted users
     */
    function setWhitelist(address[] calldata newAddresses) public onlyOwner {
        // At least one royaltyReceiver is required.
        require(newAddresses.length > 0, "No user details provided");
        // Check on the maximum size over which the for loop will run over.
        require(newAddresses.length < 2000, "Too many userss to whitelist");
        for (uint256 i = 0; i < newAddresses.length; i++) {
            require(mapSize < 2000, "Maximum Users already whitelisted");
            whitelist[newAddresses[i]] = true;
            mapSize++;
        }
    }

    /**
     * @dev remove whitelisted users
     */
    function removeWhitelist(address[] calldata currentAddresses) public onlyOwner {
        // At least one royaltyReceiver is required.
        require(currentAddresses.length > 0, "No user details provided");
        // Check on the maximum size over which the for loop will run over.
        require(currentAddresses.length <= 5, "Too many userss to whitelist");
        for (uint256 i = 0; i < currentAddresses.length; i++) {
            delete whitelist[currentAddresses[i]];
            mapSize--;
        }
    }

    /**
     * @dev Returns the base URI of the contract
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Set the base URI of the contract. Only owner and Media contract(if configured)
     * can call this function.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;

        emit BaseURI(baseURI);
    }

    /**
     * @param creator address of the owner and creator of the NFT
     * @param royaltyReceiver an array of address that will recieve royalty. Max upto 5.
     * @param tokenRoyaltyInBips an array of royalty percentages. It should match the number of reciever addresses. Max upto 5.
     * @dev safemint() for minting the tokens.
     * @dev internal setTokenURI() to set the token URI for the minted token
     * @dev internal setTokenRoyalty() to set the rolayty at token level.
     */
    function safeMint(
        address creator,
        bool tokenRoyalty,
        address[] memory royaltyReceiver,
        uint96[] memory tokenRoyaltyInBips
    ) public {
        if (whitelistEnabled == false) {
            require(msg.sender == owner(), "Address not whitelisted");
        }
        if (whitelistEnabled == true) {
            require(whitelist[msg.sender], "Address not whitelisted");
        }
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(creator, tokenId);
        _creators[tokenId] = creator;
        //If Author royalty is set to true
        if (tokenRoyalty) {
            _setTokenRoyalty(tokenId, royaltyReceiver, tokenRoyaltyInBips);
        }
        //Increment tokenId
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice This function is used for burning an existing NFT.
     * @dev _burn is an inherited function from ERC721.
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
        delete _creators[tokenId];
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
