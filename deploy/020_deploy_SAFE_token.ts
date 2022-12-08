import { deployAndTell } from '@utils/deployFunc';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async hre => {
  const {
    deployments: { deploy },
  } = hre;

  const { deployer, busd, liquidity, investments, management, referrals } = await hre.getNamedAccounts();

  const vault = await hre.deployments.get('SafeVault');

  await deployAndTell(deploy, 'SafeToken', {
    from: deployer,
    proxy: 'initialize',
    args: [busd, vault.address, liquidity, investments, management, referrals],
  });
};
export default func;
func.tags = ['SafeToken'];
