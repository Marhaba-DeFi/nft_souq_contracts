// const hre = require('hardhat');
const ethers = require('ethers');
const privateKeys = [
  '4a0493f32ce8ecd8c391283a16dc4df388fd9f6aeab2d34ecb5f79f26e696585',
  'ffbbd18e6a0c414d6e08759a023a759c20ef68c29003439e901e8f1b25d5c6a7',
  '9a3b9f8817042cb53831e014eb24453e4f2cfd60bec4412990fa0b88f437cd31',
  '7829cb373c8d0a3ed53842271567206710dae69f3064d28d89304d0ff5a1bff9',
];

function generatedWallets (provider) {
  console.log('got the call *******');
  return privateKeys.map((key) => {
    return new ethers.Wallet(key, provider);
  });
}

module.exports = {
  generatedWallets,
};
