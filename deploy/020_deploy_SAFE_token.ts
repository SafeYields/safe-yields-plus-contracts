import { taxDistributionForSafeToken, wallets } from '@config';
import { deployAndTell } from '@utils/deployFunc';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async hre => {
  const {
    deployments: { deploy },
  } = hre;

  const { deployer, busd } = await hre.getNamedAccounts();

  const vault = await hre.deployments.get('SafeVault');

  await deployAndTell(deploy, 'SafeToken', {
    from: deployer,
    proxy: 'initialize',
    args: [busd, vault.address, await wallets(hre), taxDistributionForSafeToken],
  });
};
export default func;
func.tags = ['SafeToken'];
