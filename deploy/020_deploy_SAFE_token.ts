import { tax, taxDistributionForSafeToken } from '@config';
import { deployAndTell } from '@utils/deployFunc';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async hre => {
  const {
    deployments: { deploy },
  } = hre;

  const { deployer, usdc } = await hre.getNamedAccounts();

  const vault = await hre.deployments.get('SafeVault');

  const taxDistribution = Object.values(taxDistributionForSafeToken);

  await deployAndTell(deploy, 'SafeToken', {
    from: deployer,
    proxy: 'initialize',
    args: [
      usdc,
      vault.address,
      [process.env.TREASURY_ADDRESS, process.env.MANAGEMENT_ADDRESS],
      taxDistribution,
      tax.buyTaxPercent,
      tax.sellTaxPercent,
    ],
  });
};
export default func;
func.tags = ['SafeToken'];
