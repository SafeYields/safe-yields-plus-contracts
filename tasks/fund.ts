import { announce, error, info, networkInfo, success } from '@utils/output.helper';
import erc20abi from 'abi/erc20abi.json';
import assert from 'assert';
import { task, types } from 'hardhat/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

const MAINNET_BUSD_WHALE_ADDRESS = '0x8894e0a0c962cb723c1976a4421c95949be2d4e3';

const beTheWhale = async (hre: HardhatRuntimeEnvironment, accountToFund: string, amountToTransfer?: number) => {
  const accountToInpersonate = MAINNET_BUSD_WHALE_ADDRESS;
  await hre.network.provider.request({
    method: 'hardhat_impersonateAccount',
    params: [accountToInpersonate],
  });
  const whaleSigner = await hre.ethers.getSigner(accountToInpersonate);
  const signer = (await hre.ethers.getSigners())[0];
  await (
    await signer.sendTransaction({
      to: MAINNET_BUSD_WHALE_ADDRESS,
      value: hre.ethers.utils.parseEther('1.0'),
      gasLimit: 8_000_000,
    })
  ).wait();

  const { busd } = await hre.getNamedAccounts();

  for (const token of [busd]) {
    const contract = new hre.ethers.Contract(token, erc20abi, whaleSigner);
    const toTransfer =
      (amountToTransfer && hre.ethers.utils.parseEther(amountToTransfer.toString())) ??
      (await contract.balanceOf(accountToInpersonate));
    await (await contract.connect(whaleSigner).transfer(accountToFund, toTransfer)).wait();
  }
};

export default task('fund', 'get BUSD from a whale')
  .addOptionalParam(
    'account',
    "The named account to get BUSD, e.g. 'management', 'vault', or 'all'",
    'deployer',
    types.string,
  )
  .addOptionalParam('user', 'user address to get', undefined, types.string)
  .addOptionalParam('amount', 'The amount to transfer to the deployer', 10_000, types.int)
  .setAction(async ({ account, user, amount }, hre) => {
    const { getNamedAccounts } = hre;
    await networkInfo(hre, info);

    assert((await hre.getChainId()) === '1337', 'Not applicable to live networks!');

    const namedAccounts = await getNamedAccounts();
    if (user === undefined && account !== 'all' && !namedAccounts[account]) {
      error(`Named account ${account} or user not set`);
      return;
    }
    const accounts = user ? [user] : account === 'all' ? Object.values(namedAccounts) : [namedAccounts[account]];

    for (const account of accounts) {
      announce(`Funding ${account} with ${amount.toLocaleString()} BUSD...`);
      await beTheWhale(hre, account, amount);
      success(`${amount.toLocaleString()} BUSD has been sent to ${account}`);
    }
  });
