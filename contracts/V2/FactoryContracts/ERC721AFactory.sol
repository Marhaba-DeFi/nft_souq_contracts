
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title ERC721A factory contract
 * @dev This contract inherits from ERC721A Azuki smart contract, openzeppelin pausable 
 * and ERC2981 royalty contracts.
 * ERC721A bulks mints NFTs while saving considerable gas by eliminating enumarable function
 */
contract ERC721AFactory is ERC721A, ERC2981, Pausable {
    address private _mediaContract;
    address public owner;
    uint96 royaltyFeesInBips;
    address royaltyAddress;
	string public baseURI = "";

	// Mapping from token ID to creator address
    mapping(uint256 => address) nftToCreators;
	constructor(
        string memory name_, 
        string memory symbol_,
        uint96 _royaltyFeesInBips,
        address _royaltyReciever
        )
        ERC721A(name_, symbol_)
    {
        owner = msg.sender;
        bytes memory validateName = bytes(name_); // Uses memory
        bytes memory validateSymbol = bytes(symbol_);
        require( validateName.length != 0 && validateSymbol.length != 0, "ERC721A: Choose a name and symbol");
        _setDefaultRoyalty(_royaltyReciever, _royaltyFeesInBips);
    }

    modifier onlyOwner (){
        require(msg.sender == owner || msg.sender == _mediaContract, "Not the owner");
        _;
    }

	/**
	* @dev Configure media contract 
	 */
    function configureMedia(address mediaContractAddress) external onlyOwner{
        // TODO: Only Owner Modifier
        require(
            mediaContractAddress != address(0),
            "ERC1155Factory: Invalid Media Contract Address!"
        );
        require(
            _mediaContract == address(0),
            "ERC1155Factory: Media Contract Already Configured!"
        );

        _mediaContract = mediaContractAddress;
    }

	/**
	* @dev pause function to pause minting. 
	 */
	function pause() public onlyOwner {
        _pause();
    }

	/**
	* @dev unpause function to resume minting. 
	 */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    * @dev This function is used fot minting.
    */
    function mint(uint256 _quantity, address _creator) public onlyOwner  whenNotPaused 
	{
        _safeMint(_creator, _quantity);
        //TODO: mapping of creators
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
    }

	/**
	 * @dev Implementation of royalties. Overrides the supportsInterface of ERC721A and ERC2981
	 */
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721A, ERC2981)returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }
}