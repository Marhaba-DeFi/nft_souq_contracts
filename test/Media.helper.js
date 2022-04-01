const { convertFromBigNumber } = require('../utils/util');

/**
 *
 * @param {*} mediaContract
 * @param {*} user
 * @param {*} params
 * @returns tx
 */
async function mintTokens(mediaContract, user, params) {
  // mint tokens and return the tx
  const tx = await mediaContract.connect(user).mintToken(params);
  return tx;
}
/**
 *
 * @param {*} tx
 * @returns _tokenCounter
 */
async function fetchMintEvent(tx) {
  // wait for tx to confirm fetch the events, check either its relevent and return results
  tx = await tx.wait(); // 0ms, as tx is already confirmed
  const event = tx.events.find((event) => event.event === 'TokenCounter');
  const [_tokenCounter] = event.args;
  console.log('token minted with id ', _tokenCounter.toString());
  return _tokenCounter;
}
/**
 *
 * @param {*} contract
 * @param {*} from
 * @param {*} to
 * @param {*} amount
 */
async function approveTokens(contract, from, to, amount) {
  await contract.connect(from).approve(to, amount);
}
/**
 *
 * @param {*} mediaContract
 * @param {*} from
 * @param {*} tokenId
 * @param {*} bidParams
 */
async function setBid(mediaContract, from, tokenId, bidParams) {
  // send bid to Media Contract
  return mediaContract.connect(from).setBid(
    tokenId, // _tokenCounter.toString(),
    bidParams,
    { from: from.address },
  );
}
/**
 *
 * @param {*} contract
 * @param {*} users
 * @returns
 */
async function getBalance(contract, users) {
  // fetch balances for an multiple addresses
  const balances = {};
  for (let index = 0; index < users.length; index++) {
    const address = users[index].address;
    balances[users[index].name] = convertFromBigNumber(
      await contract.balanceOf(address),
    );
  }
  console.log('Token Balances ', balances);
  return balances;
}

/**
 *
 * @param {*} contract
 * @param {*} users
 * @returns
 */
async function getBalanceNFT(contract, users) {
  // fetch balances for an multiple addresses
  const balances = {};
  for (let index = 0; index < users.length; index++) {
    const address = users[index].address;
    balances[users[index].name] = parseInt(await contract.balanceOf(address));
  }
  console.log('NFT Balances ', balances);
  return balances;
}

/**
 * @param {*} contract
 * @param {*} tokenId
 * @returns
 */
async function endAuction(mediaContract, from, tokenId) {
  // send bid to Media Contract
  return mediaContract.connect(from).endAuction(
    tokenId, // _tokenCounter.toString(),
    { from: from.address },
  );
}

/**
 * @param {*} contract
 * @param {*} tokenId
 * @returns
 */
async function cancelAuction(mediaContract, from, tokenId) {
  // send bid to Media Contract
  return mediaContract.connect(from).cancelAuction(
    tokenId, // _tokenCounter.toString(),
    { from: from.address },
  );
}

/**
 * @param {*} contract
 * @param {*} tokenId
 * @returns
 */
async function setAsk(mediaContract, from, tokenId, askParams) {
  // send bid to Media Contract
  return mediaContract.connect(from).setAsk(
    tokenId, // _tokenCounter.toString(),
    askParams,
    { from: from.address },
  );
}

async function addCurrency(mediaContract, from, tokenAddress) {
  // addCurrency function to add admin approved token addresses
  return mediaContract
    .connect(from)
    .addCurrency(tokenAddress, { from: from.address });
}

module.exports = {
  mintTokens,
  fetchMintEvent,
  approveTokens,
  setBid,
  getBalance,
  endAuction,
  getBalanceNFT,
  cancelAuction,
  setAsk,
  addCurrency,
};
