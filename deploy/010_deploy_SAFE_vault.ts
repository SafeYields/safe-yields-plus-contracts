import { deployAndTell } from '@utils/deployFunc';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async hre => {
  const {
    deployments: { deploy },
  } = hre;

  const { deployer, usdc } = await hre.getNamedAccounts();

  await deployAndTell(deploy, 'SafeVault', {
    from: deployer,
    proxy: 'initialize',
    args: [usdc],
  });
};
export default func;
func.tags = ['SafeVault'];
