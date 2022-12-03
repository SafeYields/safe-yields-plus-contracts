import { deployAndTell } from '@utils/deployFunc';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async hre => {
  const {
    deployments: { deploy },
  } = hre;

  const { deployer } = await hre.getNamedAccounts();

  await deployAndTell(deploy, 'SafeToken', {
    from: deployer,
    proxy: 'initialize',
  });
};
export default func;
func.tags = ['SafeToken'];
