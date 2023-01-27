import { NFTTiers } from '@config';
import { SafeNFT, SafeVault } from '@contractTypes/contracts';
import { ISafeToken } from '@contractTypes/contracts/interfaces';
import { formattedFromWei, info, networkInfo } from '@utils/output.helper';
import erc20abi from 'abi/erc20abi.json';
import { task } from 'hardhat/config';

task('accounts', 'Get the address and balance information (BNB, SAFE, USDC) for the accounts.')
  .addOptionalParam('user', '0x... address to check')
  .setAction(async ({ user }, hre) => {
    const {
      getNamedAccounts,
      deployments,
      ethers,
      ethers: {
        utils: { formatEther: fromWei },
      },
    } = hre;
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
            BNB: formattedFromWei(await ethers.provider.getBalance(accountAddress)),
            USDC: formattedFromWei(await usdcContract.balanceOf(accountAddress)),
            SAFE: formattedFromWei(await tokenContract.balanceOf(accountAddress)),
            SafeNFTTier1: Number(await nftContract.balanceOf(accountAddress, NFTTiers.Tier1)),
            SafeNFTTier2: Number(await nftContract.balanceOf(accountAddress, NFTTiers.Tier2)),
            SafeNFTTier3: Number(await nftContract.balanceOf(accountAddress, NFTTiers.Tier3)),
            SafeNFTTier4: Number(await nftContract.balanceOf(accountAddress, NFTTiers.Tier4)),
          };
        }),
    );
    console.table(table);

    info(`Vault totalSupply: ${fromWei(await vaultContract.totalSupply())}`);
    info(`Safe price: ${fromWei(await tokenContract.price())}`);
  });
