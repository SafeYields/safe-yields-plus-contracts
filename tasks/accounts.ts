import { NFTTiers } from '@config';
import { SafeNFT, SafeVault } from '@contractTypes/contracts';
import { ISafeToken } from '@contractTypes/contracts/interfaces';
import { formattedFromBigNumber, fromBigNumber, info, networkInfo } from '@utils/output.helper';
import erc20abi from 'abi/erc20abi.json';
import { task } from 'hardhat/config';

task('accounts', 'Get the address and balance information (ETH, SAFE, USDC) for the accounts.')
  .addOptionalParam('user', '0x... address to check')
  .setAction(async ({ user }, hre) => {
    const { getNamedAccounts, deployments, ethers } = hre;
    const namedAccounts = await getNamedAccounts();
    const { usdc } = namedAccounts;
    await networkInfo(hre, info);
    info('\n 📡 Querying balances...');
    const usdcContract = await ethers.getContractAt(erc20abi, usdc);

    const tokenDeployment = await deployments.get('SafeToken');
    const nftDeployment = await deployments.get('SafeNFT');
    const vaultDeployment = await deployments.get('SafeVault');

    const nftContract = await ethers.getContract<SafeNFT>('SafeNFT');
    const vaultContract = await ethers.getContract<SafeVault>('SafeVault');
    const tokenContract = await ethers.getContract<ISafeToken>('SafeToken');

    const accounts = {
      user,
      ...namedAccounts,
      treasury: process.env.TREASURY_ADDRESS,
      management: process.env.MANAGEMENT_ADDRESS,
      SafeNFT: nftDeployment.address,
      SafeToken: tokenDeployment.address,
      SafeVault: vaultDeployment.address,
    };

    const table = await Promise.all(
      Object.entries(accounts)
        .filter(([_, accountAddress]) => accountAddress)
        .map(async ([accountName, accountAddress]) => {
          return {
            name: accountName,
            address: accountAddress,
            ETH: formattedFromBigNumber(await ethers.provider.getBalance(accountAddress), 18),
            USDC: formattedFromBigNumber(await usdcContract.balanceOf(accountAddress)),
            SAFE: formattedFromBigNumber(await tokenContract.balanceOf(accountAddress)),
            SafeNFTTier1: Number(await nftContract.balanceOf(accountAddress, NFTTiers.Tier1)),
            SafeNFTTier2: Number(await nftContract.balanceOf(accountAddress, NFTTiers.Tier2)),
            SafeNFTTier3: Number(await nftContract.balanceOf(accountAddress, NFTTiers.Tier3)),
            SafeNFTTier4: Number(await nftContract.balanceOf(accountAddress, NFTTiers.Tier4)),
          };
        }),
    );
    console.table(table);

    info(`Vault totalSupply: ${fromBigNumber(await vaultContract.totalSupply(), 6)}`);
    info(`Safe price: ${fromBigNumber(await tokenContract.price(), 6)}`);
  });
