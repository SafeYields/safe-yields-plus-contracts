import { PRESALE_START_DATE, WEEK, discountedPresalePriceNFT } from '@config';
import { SafeNFT, SafeToken, SafeVault } from '@contractTypes/contracts';
import { deployInfo, deploySuccess, displayDiscountedPresalePriceNFT } from '@utils/output.helper';
import { DeployFunction } from 'hardhat-deploy/types';
import moment from 'moment';

const func: DeployFunction = async hre => {
  const tokenContract = await hre.ethers.getContract<SafeToken>('SafeToken');
  const vault = await hre.ethers.getContract<SafeVault>('SafeVault');
  const nft = await hre.deployments.get('SafeNFT');
  for (const address of [
    process.env.TREASURY_ADDRESS || hre.ethers.constants.AddressZero,
    process.env.MANAGEMENT_ADDRESS || hre.ethers.constants.AddressZero,
    vault.address,
    nft.address,
  ]) {
    if (!(await tokenContract.whitelist(address))) {
      deployInfo(`Authorizing SafeToken for ${address}`);
      await (await tokenContract.whitelistAdd(address)).wait();
    } else {
      deployInfo(`SafeToken for ${address} already authorized`);
    }
  }

  deployInfo('Setting SafeToken for SafeVault');
  await (await vault.setSafeToken(tokenContract.address)).wait();
  deploySuccess('Done.');

  const nftContract = await hre.ethers.getContract<SafeNFT>('SafeNFT');
  if (!(await nftContract.presale())) {
    deployInfo(`Setting presale to true`);
    await (await nftContract.togglePresale()).wait();
    deployInfo(
      `Setting presale start date ${moment.unix(PRESALE_START_DATE(hre.network.name)).format('DD.MM.YYYY HH:mm:ss')}`,
    );
    await (await nftContract.setPresaleStartDate(PRESALE_START_DATE(hre.network.name), WEEK(hre.network.name))).wait();
    deployInfo(`Setting discounted price table to: `);
    displayDiscountedPresalePriceNFT(discountedPresalePriceNFT, deployInfo);
    await (await nftContract.setDiscountedPriceTable(discountedPresalePriceNFT.map(o => Object.values(o)))).wait();
  } else {
    deployInfo(`Presale is already true, skipping setting start date and discounted price`);
  }
};
export default func;
func.tags = ['Config'];
