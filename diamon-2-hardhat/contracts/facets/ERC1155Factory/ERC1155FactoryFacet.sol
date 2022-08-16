// SPDX-License-Identifier: MIT
/**
 * ERC1155FactoryFacet is used to mint NFTs that are ERC1155 compliant.
 * The mint function can only be called from souq Media contract.
 * It is initialized with name and symbol and default royalty.
 *
 */

pragma solidity ^0.8.0;

import "../ERC1155/ERC1155Facet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./LibERC1155FactoryStorage.sol";
import "../../libraries/LibURI.sol";

contract ERC1155FactoryFacet is ERC1155Facet {
    using Strings for uint256;

	modifier onlyMediaCaller() {
        require(msg.sender == s._mediaContract, "ERC721Factory: Unauthorized Access!");
        _;
    }

    function erc1155FactoryFacetInit(string memory name_, string memory symbol_) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        require(bytes(es.name).length == 0 && bytes(es.symbol).length == 0, "ALREADY_INITIALIZED");

        require(bytes(name_).length != 0 && bytes(symbol_).length != 0, "INVALID_PARAMS");

		require(msg.sender == ds.contractOwner, "Must own the contract.");
        es.name = name_;
        es.symbol = symbol_;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        es._tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @notice This function is used for minting new NFT in the market.
     * @param tokenId tokenId
     * @param creator address of the owner and creator of the NFT
     * @param tokenURI tokenURI
     * @param totalSupply copies of the NFT to be minted
     * @param royaltyReceiver an array of address that will recieve royalty. Max upto 5.
     * @param tokenRoyaltyInBips an array of royalty percentages. It should match the number of reciever addresses. Max upto 5.
     * @dev safemint() for minting the tokens.
     * @dev internal setTokenURI() to set the token URI for the minted token
     * @dev internal setTokenRoyalty() to set the rolayty at token level.
     */
    function mint(
        uint256 tokenId,
        address creator,
        uint256 totalSupply,
        string memory tokenURI,
		address [] memory royaltyReceiver,
		uint96 [] memory tokenRoyaltyInBips

    ) external  onlyMediaCaller {
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        es.nftToOwners[tokenId] = creator;
        es.nftToCreators[tokenId] = creator;
        _mint(creator, tokenId, totalSupply, "");
        _setTokenURI(tokenId, tokenURI);
        //setTokenRoyalty
    }

    /**
     * @notice This Method is used to Transfer Token
     * @dev This method is used while Direct Buy-Sell takes place
     *
     * @param _from Address of the Token Owner to transfer
     * @param _to Address of the Token receiver
     * @param _tokenID TokenID of the Token to transfer
     * @param _amount copies of Tokens to transfer, in case of Fungible Token transfer
     *
     * @return bool Transaction Status
     */

    function transfer(
        address _from,
        address _to,
        uint256 _tokenID,
        uint256 _amount
    ) external returns (bool) {
        require(_to != address(0x0), "ERC1155Factory: _to must be non-zero.");
        safeTransferFrom(_from, _to, _tokenID, _amount, "");
        return true;
    }

	/**
	 * @notice This function is used for burning an existing NFT.
	 * @dev _burn is an inherited function from ERC1155.
	 * @dev Destroys `amount` tokens of token type `tokenId` from `from` account
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
	 */
	function burn(address from, uint256 tokenId, uint256 amount) external  
	{
        _burn(from, tokenId, amount);
    }
}
