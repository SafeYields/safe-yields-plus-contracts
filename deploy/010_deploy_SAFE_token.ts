import { deployAndTell } from '@utils/deployFunc';
import assert from 'assert';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async hre => {
  const {
    getNamedAccounts,
    deployments: { deploy },
    getChainId,
    ethers,
  } = hre;

  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  await deployAndTell(deploy, 'DEFOToken', {
    proxy: {
      owner: defoTokenOwner,
      methodName: 'initialize',
    },
    owner: defoTokenOwner,
    args: [chainId],
  });

  const defoSignerIndex = namedAccountsIndex.defoTokenOwner as number;
  const defoTokenOwnerSigner = (await ethers.getSigners())[defoSignerIndex];

  assert(defoTokenOwnerSigner.address === defoTokenOwner);
};

export default func;
func.tags = ['DEFOToken'];
