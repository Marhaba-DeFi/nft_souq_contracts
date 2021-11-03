require('@nomiclabs/hardhat-web3');
task('balanceOf', 'Prints an account\'s balance')
  .addParam('from', 'The account\'s name')
  .addParam('chain', 'The network\'s name')
  .setAction(async (taskArgs) => {
    const { getWalletsMappings, mintArray } = require('../test/Media.Objects');
    const { mintTokens } = require('../test/Media.helper');
    const fs = require('fs');
    const path = require('path');
    const contractAddresses = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, '../config.json'), 'utf8'),
    );
    const hre = require('hardhat');
    console.log('mint array ', mintArray);
    const wallets = await getWalletsMappings();
    const from = taskArgs.from;
    const chain = taskArgs.chain;
    let media = await hre.ethers.getContractFactory('Media');
    media = await media.attach(contractAddresses[chain].MEDIA);
    mintArray[9] = contractAddresses[chain].MARHABA;
    const tx = await mintTokens(media, wallets[from], mintArray);
    await tx.wait();
    console.log('token minted with tx details ', tx);
  });
