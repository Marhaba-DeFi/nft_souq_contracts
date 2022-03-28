import { task } from 'hardhat/config';
const fs = require('fs');

const basePath = '/contracts/facets/';
const libraryBasePath = '/contracts/libraries/';

task(
  'diamondABI',
  'Generates ABI file for diamond, includes all ABIs of facets',
).setAction(async () => {
  let files = fs.readdirSync('.' + basePath);
  const abi = [];
  for (const file of files) {
    const jsonFile = file.replace('sol', 'json');
    let json = fs.readFileSync(`./artifacts/${basePath}${file}/${jsonFile}`);
    json = JSON.parse(json);
    abi.push(...json.abi);
  }
  files = fs.readdirSync('.' + libraryBasePath);
  for (const file of files) {
    const jsonFile = file.replace('sol', 'json');
    let json = fs.readFileSync(
      `./artifacts/${libraryBasePath}${file}/${jsonFile}`,
    );
    json = JSON.parse(json);
    abi.push(...json.abi);
  }
  files = fs.readdirSync('.' + sharedLibraryBasePath);
  for (const file of files) {
    const jsonFile = file.replace('sol', 'json');
    let json = fs.readFileSync(
      `./artifacts/${sharedLibraryBasePath}${file}/${jsonFile}`,
    );
    json = JSON.parse(json);
    abi.push(...json.abi);
  }
  const finalAbi = JSON.stringify(abi);
  fs.writeFileSync('./diamondABI/diamond.json', finalAbi);
  console.log('ABI written to diamondABI/diamond.json');
});
