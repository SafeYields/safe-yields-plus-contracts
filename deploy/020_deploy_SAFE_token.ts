import { deployAndTell } from '@utils/deployFunc';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async hre => {
  const {
    deployments: { deploy },
  } = hre;

  const { deployer, busd, liquidity, investments, management, referrals } = await hre.getNamedAccounts();

  const vault = await hre.deployments.get('SafeVault');
  const wallets = [liquidity, investments, management, referrals];
  const distribution = [5000, 2950, 2000, 50];

  await deployAndTell(deploy, 'SafeToken', {
    from: deployer,
    proxy: 'initialize',
    args: [busd, vault.address, wallets, distribution],
  });
};
export default func;
func.tags = ['SafeToken'];
