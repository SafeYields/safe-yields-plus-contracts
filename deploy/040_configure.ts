import { PRESALE_START_DATE, WEEK, discountedPresalePriceNFT } from '@config';
import { SafeNFT, SafeToken } from '@contractTypes/contracts';
import { deployInfo, displayDiscountedPresalePriceNFT } from '@utils/output.helper';
import { DeployFunction } from 'hardhat-deploy/types';
import moment from 'moment';

const func: DeployFunction = async hre => {
  const { treasury, management } = await hre.getNamedAccounts();

  const tokenContract = await hre.ethers.getContract<SafeToken>('SafeToken');
  const vault = await hre.deployments.get('SafeVault');
  const nft = await hre.deployments.get('SafeNFT');
  for (const address of [treasury, management, vault.address, nft.address]) {
    if ((await tokenContract.admin(address)).isZero()) {
      deployInfo(`Authorizing SafeToken for ${address}`);
      await (await tokenContract.rely(address)).wait();
    } else {
      deployInfo(`SafeToken for ${address} already authorized`);
    }
  }
  const nftContract = await hre.ethers.getContract<SafeNFT>('SafeNFT');
  if (!(await nftContract.presale())) {
    deployInfo(`Setting presale to true`);
    await (await nftContract.togglePresale()).wait();
    deployInfo(`Setting presale start date ${moment.unix(PRESALE_START_DATE).format('DD.MM.YYYY HH:mm:ss')}`);
    await (await nftContract.setPresaleStartDate(PRESALE_START_DATE, WEEK)).wait();
    deployInfo(`Setting discounted price table to: `);
    displayDiscountedPresalePriceNFT(discountedPresalePriceNFT, deployInfo);
    await (await nftContract.setDiscountedPriceTable(discountedPresalePriceNFT.map(o => Object.values(o)))).wait();
  } else {
    deployInfo(`Presale is already true, skipping setting start date and discounted price`);
  }
};
export default func;
func.tags = ['Config'];
