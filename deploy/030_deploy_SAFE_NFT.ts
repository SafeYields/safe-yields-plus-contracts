import { deployAndTell } from '@utils/deployFunc';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async hre => {
  const {
    deployments: { deploy },
  } = hre;

  const { deployer, liquidity, investments, management, referrals } = await hre.getNamedAccounts();

  const token = await hre.deployments.get('SafeToken');
  // const wallets = [liquidity, investments, management, referrals];
  const price = [5000, 2950, 2000, 50];
  const distribution = [5000, 2950, 2000, 50];

  await deployAndTell(deploy, 'SafeNFT', {
    from: deployer,
    proxy: 'initialize',
    args: ['', price, token.address, distribution],
  });
};
export default func;
func.tags = ['SafeNFT'];
