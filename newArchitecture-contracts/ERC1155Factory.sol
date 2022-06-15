// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract contract1155 is Ownable, Pausable, ERC1155 {
   using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    mapping(uint256 => string) private uris;
    mapping(uint256 => uint256) private maxSupply;
    mapping(uint256 => uint256) private minted;


    constructor(
        string memory name, 
        string memory symbol, 
        string memory version
    ) ERC1155(name, symbol) {

        bytes memory tempName = bytes(name); // Uses memory
        bytes memory tempSymbol = bytes(symbol);
        require( tempName.length != 0 && tempSymbol.length != 0,
            "ERC1155: Choose a name and symbol");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setURI(uint256 tokenId, string memory newuri) internal {
        // _setURI(newuri);
        uris[tokenId] = newuri;
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        return(uris[tokenId]);
    }

    function mint(address _account, uint256 _supply, uint256 _copies, string memory _uri)
        public whenNotPaused returns(uint256, uint256) {

        //Checks
        require(_copies <= _supply, "Number of copies exceeds the total supply");

        //Effects
        uint256 id = tokenIdCounter.current();
        maxSupply[id] = _supply;
        minted[id] += _copies;
        tokenIdCounter.increment();

        //Interaction
        _mint(_account, id, _copies, "");
        setURI(id, _uri);
        return(id, _copies);
    }

    function mintMore(address _account, uint256 _id, uint256 _copies)
        public whenNotPaused returns(uint256, uint256) {

            //Checks
            require(minted[_id] + _copies <= maxSupply[_id], "Cannot mint more than total supply");

            //Effects
            minted[_id] += _copies;

            //Interaction
            _mint(_account, _id, _copies, "");
            return(_id, _copies);
    }    

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
    {
        _mintBatch(to, ids, amounts, data);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}