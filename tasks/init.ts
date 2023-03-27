import { SafeToken, SafeVault } from '@contractTypes/contracts';
import { error, info, networkInfo, success, toBigNumber } from '@utils/output.helper';
import erc20abi from 'abi/erc20abi.json';
import { ethers } from 'ethers';
import { task } from 'hardhat/config';

export default task('init', 'funds th vault with 1 usdc and mints 1 safe to set the price').setAction(
  async (_, hre) => {
    const { getNamedAccounts } = hre;
    await networkInfo(hre, info);

    const { usdc } = await getNamedAccounts();
    const usdcContract = new hre.ethers.Contract(usdc, erc20abi, (await hre.ethers.getSigners())[0]);
    const safeTokenContract = await hre.ethers.getContract<SafeToken>('SafeToken');
    const safeVaultContract = await hre.ethers.getContract<SafeVault>('SafeVault');
    await (await usdcContract.approve(safeVaultContract.address, hre.ethers.constants.MaxUint256)).wait();

    info('Minting 1 SAFE to the vault...');
    const safeVaultSAFEBalance = await safeTokenContract.balanceOf(safeVaultContract.address);
    if (safeVaultSAFEBalance.eq(ethers.constants.Zero)) {
      (await safeTokenContract.mint(safeVaultContract.address, toBigNumber(1))).wait;
      success('Done.');
    } else error('SAFE already minted to the vault. Skipping minting.');

    if (safeVaultSAFEBalance.eq(ethers.constants.Zero)) {
      info('Depositing 1 USDC to the vault...');
      const safeVaultUSDCBalance = await usdcContract.balanceOf(safeVaultContract.address);
      if (safeVaultUSDCBalance.eq(ethers.constants.Zero)) {
        (await safeVaultContract.deposit(toBigNumber(1, 6))).wait;
        success('Done.');
      } else error('USDC already deposited to the vault. Skipping depositing.');
    }
  },
);
