// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract ERC721AFactory is ERC721A, ERC2981 {
    address private _mediaContract;
    address public owner;
    uint96 royaltyFeesInBips;
    address royaltyAddress;

    constructor(
        string memory name_, 
        string memory symbol_,
        uint96 _royaltyFeesInBips,
        address _royaltyReciever
        )
        ERC721A(name_, symbol_)
    {
        owner = msg.sender;
        bytes memory name = bytes(name_); // Uses memory
        bytes memory symbol = bytes(symbol_);
        require( name.length != 0 && symbol.length != 0, "ERC721A: Choose a name and symbol");
        _setDefaultRoyalty(_royaltyReciever, _royaltyFeesInBips);
    }
    string public baseURI = "";
    mapping(uint256 => address) nftToCreators;

    modifier onlyOwner (){
        require(msg.sender == owner || msg.sender == _mediaContract, "Not the owner");
        _;
    }

    function configureMedia(address _mediaContractAddress) external onlyOwner{
        // TODO: Only Owner Modifier
        require(
            _mediaContractAddress != address(0),
            "ERC1155Factory: Invalid Media Contract Address!"
        );
        require(
            _mediaContract == address(0),
            "ERC1155Factory: Media Contract Already Configured!"
        );

        _mediaContract = _mediaContractAddress;
    }

    /* 
    @notice This function is used fot minting 
     new NFT in the market.
    @dev 'msg.sender' will pass the 'quantity' to be minted and 
     the respective NFT details.
    */
    function mint(uint256 quantity, address _creator) public onlyOwner  {
        _safeMint(_creator, quantity);
        //TODO: mapping of creators

    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

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