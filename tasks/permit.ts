import { announce, info, networkInfo, sayMaximumForMaxUint, success } from '@utils/output.helper';
import { task, types } from 'hardhat/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

import erc20abi from '../abi/erc20abi.json';

export default task('permit', 'approve SafeToken to spend USDC')
  .addOptionalParam(
    'user',
    'an address to permit to (should be impersonated earlier with get-some-gems for localhost forking mainent)',
    undefined,
    types.string,
  )
  .setAction(async ({ user }, hre: HardhatRuntimeEnvironment) => {
    const { getNamedAccounts, deployments, ethers } = hre;
    const { deployer, usdc } = await getNamedAccounts();
    await networkInfo(hre, info);
    const { address: spenderAddress1 } = await deployments.get('SafeToken');
    const { address: spenderAddress2 } = await deployments.get('SafeNFT');

    const signer = user ?? deployer;
    info(`Signer ${signer}`);
    const usdcContract = await ethers.getContractAt(erc20abi, usdc, signer);

    for (const token of [usdcContract]) {
      for (const spenderAddress of [spenderAddress1, spenderAddress2]) {
        announce(`Approving spending of USDC`);
        let allowance = await token.allowance(signer, spenderAddress);
        info(`Current allowance is ${sayMaximumForMaxUint(allowance)}`);
        if (!allowance.eq(ethers.constants.MaxUint256)) {
          info(`Calling approve for ${await token.name()}, max amount`);
          await token.approve(spenderAddress, ethers.constants.MaxUint256);
          allowance = await token.allowance(signer, spenderAddress);
          success(
            `Permission to spend granted to the contract deployed to ${spenderAddress}. Now allowance is ${sayMaximumForMaxUint(
              allowance,
            )}`,
          );
        }
      }
    }
  });
