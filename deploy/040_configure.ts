import { SafeToken } from '@contractTypes/contracts';
import { deployInfo } from '@utils/output.helper';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async hre => {
  const { investments, management } = await hre.getNamedAccounts();

  const tokenContract = await hre.ethers.getContract<SafeToken>('SafeToken');
  const vault = await hre.deployments.get('SafeVault');
  const nft = await hre.deployments.get('SafeNFT');
  for (const address of [investments, management, vault.address, nft.address]) {
    deployInfo(`Authorizing SafeToken for ${address}`);
    await (await tokenContract.rely(address)).wait();
  }
};
export default func;
func.tags = ['Config'];
