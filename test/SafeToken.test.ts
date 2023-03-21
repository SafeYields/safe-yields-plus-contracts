import { SafeToken } from '@contractTypes/contracts';
import erc20abi from 'abi/erc20abi.json';
import { expect } from 'chai';
import newDebug from 'debug';
import { Contract } from 'ethers';
import hardhat, { deployments, ethers } from 'hardhat';
import { Address } from 'hardhat-deploy/dist/types';

const debug = newDebug('safe:SafeToken.test.ts');

describe('SafeToken', () => {
  let safeTokenContract: SafeToken;
  let safeTokenContractOtherUser: SafeToken;
  let usdContract: Contract;
  let namedAccounts: { [name: string]: Address };
  let user: Address;
  let otherUsers: Address[];
  let otherUser: Address;
  const testAmount = 1000000;

  beforeEach(async () => {
    await deployments.fixture(['SafeVault', 'SafeToken', 'SafeNFT', 'Config']);
    safeTokenContract = await ethers.getContract<SafeToken>('SafeToken');
    namedAccounts = await hardhat.getNamedAccounts();
    usdContract = await ethers.getContractAt(erc20abi, namedAccounts.usdc);
    user = namedAccounts.deployer;
    otherUsers = await hardhat.getUnnamedAccounts();
    otherUser = otherUsers[0];
    safeTokenContractOtherUser = await ethers.getContract<SafeToken>('SafeToken', otherUser);
  });

  describe('mint(address _user, uint256 _amount)', () => {
    it('owner should be able to mint safe token to himself', async () => {
      await expect(safeTokenContract.mint(user, testAmount))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(ethers.constants.AddressZero, user, testAmount);
      expect(await safeTokenContract.balanceOf(user)).to.equal(testAmount);
    });

    it('owner should be able to mint safe token to anybody', async () => {
      await expect(safeTokenContract.mint(otherUser, testAmount))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(ethers.constants.AddressZero, otherUser, testAmount);
      expect(await safeTokenContract.balanceOf(otherUser)).to.equal(testAmount);
    });

    it('non-owner should not be able to mint safe token', async () => {
      await expect(safeTokenContractOtherUser.mint(otherUser, testAmount)).to.be.revertedWith(
        'SafeToken:not-authorized',
      );
    });
  });

  describe('transfer(address dst, uint256 amt)', () => {
    it('owner should be able to transfer tokens to himself', async () => {
      await safeTokenContract.mint(user, testAmount);
      await expect(safeTokenContract.transfer(user, testAmount))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(user, user, testAmount);
      expect(await safeTokenContract.balanceOf(user)).to.equal(testAmount);
    });

    it('owner should be able to transfer personal tokens to anybody', async () => {
      await safeTokenContract.mint(user, testAmount);
      await expect(safeTokenContract.transfer(otherUser, testAmount))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(user, otherUser, testAmount);
      expect(await safeTokenContract.balanceOf(otherUser)).to.equal(testAmount);
      expect(await safeTokenContract.balanceOf(user)).to.be.equal(0);
    });

    it('non-owner user should not be able to transfer tokens', async () => {
      await safeTokenContract.mint(otherUser, testAmount);
      await expect(safeTokenContractOtherUser.transfer(otherUser, testAmount)).to.be.revertedWith(
        'SafeToken: transfer-prohibited',
      );
    });

    it('non-owner user should be able to transfer tokens if whitelisted', async () => {
      await safeTokenContract.mint(otherUser, testAmount);
      await safeTokenContract.whitelistAdd(otherUser);
      await expect(safeTokenContractOtherUser.transfer(user, testAmount))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(otherUser, user, testAmount);
      expect(await safeTokenContract.balanceOf(otherUser)).to.equal(0);
      expect(await safeTokenContract.balanceOf(user)).to.be.equal(testAmount);
    });

    it('non-owner user should not be able to transfer tokens if removed from whitelist', async () => {
      await safeTokenContract.mint(otherUser, testAmount);
      await safeTokenContract.whitelistAdd(otherUser);
      await safeTokenContract.whiteListRemove(otherUser);
      await expect(safeTokenContractOtherUser.transfer(otherUser, testAmount)).to.be.revertedWith(
        'SafeToken: transfer-prohibited',
      );
    });
  });

  describe('transferFrom(address src, address dst, uint256 amt)', () => {
    it("owner should be able to transfer someone's tokens to anybodey", async () => {
      await safeTokenContract.mint(otherUser, testAmount * 1.5);
      await expect(safeTokenContract.transferFrom(otherUser, user, testAmount))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(otherUser, user, testAmount);
      expect(await safeTokenContract.balanceOf(otherUser)).to.equal(testAmount * 0.5);
      expect(await safeTokenContract.balanceOf(user)).to.equal(testAmount);
    });
  });

  describe('name', () => {
    it('Should return the contract name created in constructor', async () => {
      expect(await safeTokenContract.name()).to.equal('Safe Yields Token');
    });
  });

  describe('symbol', () => {
    it('Should return the contract symbol created in constructor', async () => {
      expect(await safeTokenContract.symbol()).to.equal('SAFE');
    });
  });

  describe('balanceOf', () => {
    it('Should return the address balance', async () => {
      await safeTokenContract.mint(user, testAmount);
      expect(await safeTokenContract.balanceOf(user)).to.equal(testAmount);
    });
  });

  describe('totalSupply', () => {
    it('Should return the contract totalSupply', async () => {
      await safeTokenContract.mint(user, testAmount);
      await safeTokenContract.mint(otherUser, testAmount);
      expect(await safeTokenContract.totalSupply()).to.equal(testAmount * 2);
    });
  });

  describe('Decimals', () => {
    it("Should return the dechimals once it's changed", async () => {
      expect(await safeTokenContract.decimals()).to.equal(6);
    });
  });

  describe('Burn token', () => {
    it('Burn token for address', async () => {
      await safeTokenContract.mint(otherUser, testAmount * 35);
      await safeTokenContract.burn(otherUser, testAmount * 12);
      expect(await safeTokenContract.balanceOf(otherUser)).to.equal(testAmount * 23);
    });
  });

  describe('Allowance token with approve', () => {
    it('Allowance token for address', async () => {
      await safeTokenContract.mint(user, testAmount * 100);
      await safeTokenContract.approve(otherUser, testAmount * 20);
      expect(await safeTokenContract.allowance(user, otherUser)).to.equal(testAmount * 20);
    });
  });

  describe('Pause', () => {
    it('should get the pause info', async () => {
      expect(await safeTokenContract.paused()).to.equal(false);
    });
    it('owner should be able to pause', async () => {
      await safeTokenContract.pause();
      expect(await safeTokenContract.paused()).to.equal(true);
    });
    it('paused contract mints to the owner', async () => {
      await safeTokenContract.pause();
      await expect(safeTokenContract.mint(user, testAmount))
        .to.emit(safeTokenContract, 'Transfer')
        .withArgs(ethers.constants.AddressZero, user, testAmount);
    });

    it("paused contract doesn't transfer", async () => {
      await safeTokenContract.pause();
      await safeTokenContract.mint(otherUser, testAmount);
      await expect(safeTokenContractOtherUser.transfer(otherUser, testAmount)).to.be.revertedWith('SafeToken:paused');
    });

    it('non-owner should not be able to pause', async () => {
      await expect(safeTokenContractOtherUser.pause()).to.be.revertedWith('SafeToken:not-authorized');
    });
  });

  describe('Price and token mechanics', async () => {
    // before(async () => {
    //   // await deployments.fixture(['SafeVault', 'SafeToken', 'SafeNFT', 'Config']);
    //   await hardhat.run('fund');
    //   await hardhat.run('fund', { user: otherUser });
    //   await hardhat.run('init');
    //   await hardhat.run('permit');
    // });

    it('should get the price', async () => {
      expect(await safeTokenContract.price()).to.equal(1e6);
    });
    //
    // describe('Price and token mechanics', async () => {
    //   it('user can get safe with buySafeForExactAmountOfUSD(uint256 _usdToSpend)', async () => {
    //     await safeTokenContractOtherUser.buySafeForExactAmountOfUSD(100e6);
    //     expect(await safeTokenContractOtherUser.balanceOf(user)).to.equal(100e6);
    //     expect(await safeTokenContractOtherUser.totalSupply()).to.equal(100e6);
    //   });
    // });
  });
});
