// SPDX-License-Identifier: CC0-1.0

/**
 * Important: This is not complete yet. More reasearch and business logic yto be added later
 */
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Interfaces/IERC4973.sol";
import "../ERC4973.sol";

contract SBTFactory is ERC4973 {
    address public owner;
	constructor(string memory name_, string memory symbol_)
        ERC4973(name_, symbol_)
    {
        owner = msg.sender;
    }

    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    mapping(uint256 => address) nftToCreators;

    modifier onlyCreator (){
        require(msg.sender == owner, "Not the owner");
        _;
    }

	function burnToken(uint256 _tokenId) external onlyCreator {
		_burn(_tokenId);
	}

	function issue(address _recipient, string memory _uri) external onlyCreator {
        uint256 id = tokenIdCounter.current();
        tokenIdCounter.increment();
		_mint(_recipient, id, _uri);
        nftToCreators[id] = msg.sender;
	}
}