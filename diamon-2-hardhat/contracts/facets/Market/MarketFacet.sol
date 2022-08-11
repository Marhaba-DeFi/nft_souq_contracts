// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./LibMarketStorage.sol";
import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibDiamond.sol";
import "../EIP712/EIP712Facet.sol";

contract MarketFacet is EIP712 {

    function marketFacetInit(
    string memory name_,
    string memory version_
    ) external {

        eip712FacetInit(name_, version_);
    }

    function setApprovedCrypto(
		address _currencyAddress, 
		bool approving
	) public {
        LibMarketStorage.MarketStorage storage es = LibMarketStorage.marketStorage();
        es._approvedCurrency[_currencyAddress] = approving;
    }

    function getApprovedCrypto(
    address _currencyAddress
	) view public returns(bool) {
        LibMarketStorage.MarketStorage storage es = LibMarketStorage.marketStorage();
        return(es._approvedCurrency[_currencyAddress]);
    }
}








