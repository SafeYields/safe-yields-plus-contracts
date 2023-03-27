import { SafeToken, SafeVault } from '@contractTypes/contracts';
import { toBigNumber } from '@utils/output.helper';
import erc20abi from 'abi/erc20abi.json';
import { expect } from 'chai';
import newDebug from 'debug';
import { Contract } from 'ethers';
import hardhat, { deployments, ethers } from 'hardhat';
import { Address } from 'hardhat-deploy/dist/types';

const debug = newDebug('safe:SafeToken.test.ts');
describe('SafeVault', () => {
  let safeTokenContract: SafeToken;
  let safeTokenContractOtherUser: SafeToken;
  let safeVaultContract: SafeVault;
  let safeVaultContractOtherUser: SafeVault;
  let usdContract: Contract;
  let usdContractOtherUser: Contract;
  let namedAccounts: { [name: string]: Address };
  let user: Address;
  let otherUsers: Address[];
  let otherUser: Address;
  // test running parameters
  const testAmount = toBigNumber(10);
  const roundingPrecisonError = 0.00001;
  const numberOfFuzzingTests = 5;
  const fuzzingTestAmount = 80_000 / numberOfFuzzingTests;

  beforeEach(async () => {
    await deployments.fixture(['SafeVault', 'SafeToken', 'SafeNFT', 'Config']);
    safeVaultContract = await ethers.getContract<SafeVault>('SafeVault');
    safeTokenContract = await ethers.getContract<SafeToken>('SafeToken');
    namedAccounts = await hardhat.getNamedAccounts();
    usdContract = await ethers.getContractAt(erc20abi, namedAccounts.usdc);
    user = namedAccounts.deployer;
    otherUsers = await hardhat.getUnnamedAccounts();
    otherUser = otherUsers[0];
    usdContractOtherUser = await ethers.getContractAt(erc20abi, namedAccounts.usdc, otherUser);
    safeVaultContractOtherUser = await ethers.getContract<SafeVault>('SafeVault', otherUser);
    safeTokenContractOtherUser = await ethers.getContract<SafeToken>('SafeToken', otherUser);
    await hardhat.run('fund');
    await hardhat.run('fund', { user: otherUser });
    await hardhat.run('init');
    await hardhat.run('permit');
    await hardhat.run('permit', { user: otherUser });
  });

  describe('deposit(uint256 _amount)', () => {
    it('anyone should be able to deposit stable coin tokens to vault', async () => {
      await expect(safeVaultContractOtherUser.deposit(testAmount))
        .to.emit(safeVaultContractOtherUser, 'Deposit')
        .withArgs(otherUser, testAmount);
      expect(await safeVaultContract.deposited(otherUser)).to.equal(testAmount);
      //that's include 1 usd deposited by init script
      expect(await safeVaultContract.totalDeposited()).to.equal(toBigNumber(1).add(testAmount));
    });
  });

  describe('remove(address _user, uint256 _amount)', () => {
    it('noone should be able to remove stable coins from vault, even contract owner', async () => {
      await safeVaultContract.deposit(testAmount);
      await expect(safeVaultContract.remove(user, testAmount)).to.be.revertedWith(
        'SafeVault: only safe token is allowed to remove liquidity',
      );
    });
  });
});
