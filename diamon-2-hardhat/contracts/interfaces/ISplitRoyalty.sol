// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface ISplitRoyalty {
    struct RoyaltyInfo {
        address[] receiver;
        uint96[] royaltyFraction;
    }
	/**
     * @notice This method is used to get the royalty amount for each recipient of the tokenID
     *
     * @return address[] of the recievers and 
	 * @return uint256[] royalty amount for Token Id
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external returns (address[] memory , uint256[] memory );

	/**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
	function feeDenominator() external returns (uint96);
	
	/**
     * @dev Sets the royalty information that all ids in this contract will default to.
     */
    function setDefaultRoyalty(
			address[] memory receiver, 
			uint96[] memory feeNumerator
		) external;

	/**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address[] memory receiver,
        uint96[] memory feeNumerator
    ) external; 

	/**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) external; 
}