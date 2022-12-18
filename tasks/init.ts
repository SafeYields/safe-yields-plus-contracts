import { SafeToken, SafeVault } from '@contractTypes/contracts';
import { info, networkInfo, success, toWei } from '@utils/output.helper';
import erc20abi from 'abi/erc20abi.json';
import { task } from 'hardhat/config';

export default task('init', 'funds th vault with 1 busd and mints 1 safe to set the price').setAction(
  async (_, hre) => {
    const { getNamedAccounts } = hre;
    await networkInfo(hre, info);

    const { busd } = await getNamedAccounts();
    const busdContract = new hre.ethers.Contract(busd, erc20abi, (await hre.ethers.getSigners())[0]);
    const safeTokenContract = await hre.ethers.getContract<SafeToken>('SafeToken');
    const safeVaultContract = await hre.ethers.getContract<SafeVault>('SafeVault');
    await (await busdContract.approve(safeVaultContract.address, hre.ethers.constants.MaxUint256)).wait();

    info('Minting 1 SAFE to the vault...');
    (await safeTokenContract.mint(safeVaultContract.address, toWei(1))).wait;
    info('Depositing 1 BUSD to the vault...');
    (await safeVaultContract.deposit(toWei(1))).wait;
    success('Done.');
  },
);
