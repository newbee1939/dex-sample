import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import UdexPool from "../artifacts/contracts/UdexPool.sol/UdexPool.json";
import { ContractFactory, Contract } from "ethers";
import { getCreate2Address } from "./lib/utilities";

// 10の三乗
const MINIMUM_LIQUIDITY = 10 ** 3;

describe("UdexPool", () => {
  async function deployPoolFixture() {
    // account（hardhatのテスト環境では、hardhat accountという特殊なアドレスが20個用意されている）
    // 例えばトークンを送るときの「誰から」に当たる部分
    const [account0, account1, account2] = await ethers.getSigners();

    // tokensのペアを生成する
    const Token = await ethers.getContractFactory("TokenTest");
    const tokenA = await Token.deploy("tokenA", "A", 18, 1000000);
    const tokenB = await Token.deploy("tokenB", "B", 18, 1000000);
    const [token0, token1] =
      tokenA.address < tokenB.address ? [tokenA, tokenB] : [tokenB, tokenA];

    // Udex
    const Factory = await ethers.getContractFactory("UdexFactory");
    const factory = await Factory.deploy();
    await factory.deployed();
    await factory.createPool(token0.address, token1.address);
    const poolAddress = await factory.getPool(token0.address, token1.address);

    // 流動性poolのコントラクトのインスタンスを作る
    const pool = new ethers.Contract(
      poolAddress,
      UdexPool.abi,
      ethers.provider
    );

    return { account0, account1, account2, factory, pool, token0, token1 };
  }

  describe("state variables", async () => {
    it("factory address", async () => {
      const { factory, pool } = await loadFixture(deployPoolFixture);
      expect(await pool.factory()).to.eq(factory.address);
    });

    it("token address", async () => {
      const { pool, token0, token1 } = await loadFixture(deployPoolFixture);
      expect(await pool.token0()).to.eq(token0.address);
      expect(await pool.token1()).to.eq(token1.address);
    });
  });

  describe("initialize", () => {
    it("not callable by user accounts", async function () {
      const { account0, account1, account2, pool, token0, token1 } =
        await loadFixture(deployPoolFixture);
      // factory以外が呼び出すことはできない
      await expect(
        pool.connect(account0).initialize(token0.address, token1.address)
      ).to.be.revertedWith("UdexPool: initialization forbidden");
      await expect(
        pool.connect(account1).initialize(token0.address, token1.address)
      ).to.be.revertedWith("UdexPool: initialization forbidden");
      await expect(
        pool.connect(account2).initialize(token0.address, token1.address)
      ).to.be.revertedWith("UdexPool: initialization forbidden");
    });
  });

  describe("mint", () => {
    it("token balances", async () => {
      const { account0, token0, token1 } = await loadFixture(deployPoolFixture);
      // account1とかaccount2に関しては残高0
      expect(await token0.balanceOf(account0.address)).to.eq(1000000);
      expect(await token1.balanceOf(account0.address)).to.eq(1000000);
    });

    it("mint liquidity to an account1 by account2", async () => {
      const { account0, account1, account2, pool, token0, token1 } =
        await loadFixture(deployPoolFixture);

      const token0Amount = 40000;
      const token1Amount = 90000;
      const liquidity = Math.sqrt(token0Amount * token1Amount);
      // mintの前にtoken0をpoolにtransferする。送り手はアカウント0（何も書かなければaccount0が実行するのがhardhatの動き）
      await token0.transfer(pool.address, token0Amount);
      // mintの前にtoken1をpoolにtransferする。送り手はアカウント0
      await token1.transfer(pool.address, token1Amount);

      // poolコントラクトにaccount2をconnectする(account2からトランザクションが送られた)
      // _mintにTranserイベントがある
      await expect(pool.connect(account2).mint(account1.address))
        .to.emit(pool, "Transfer")
        .withArgs(
          ethers.constants.AddressZero,
          account1.address,
          liquidity - MINIMUM_LIQUIDITY
        ) // mintなのでゼロアドレスからの送金
        .to.emit(pool, "Mint")
        .withArgs(account2.address, token0Amount, token1Amount);

      expect(await pool.balanceOf(account1.address)).to.eq(
        liquidity - MINIMUM_LIQUIDITY
      );
      expect(await token0.balanceOf(pool.address)).to.eq(token0Amount);
      expect(await token1.balanceOf(pool.address)).to.eq(token1Amount);
    });

    // 最初にmint関数が呼ばれた時に預け入れられたトークンの量があまりに少ないとrevertする
    it("mint reverted for insufficient initial deposit", async function () {
      const { account0, account1, account2, pool, token0, token1 } =
        await loadFixture(deployPoolFixture);
      const token0Amount = 999;
      const token1Amount = 999;
      await token0.transfer(pool.address, token0Amount);
      await token1.transfer(pool.address, token1Amount);
      await expect(
        pool.connect(account2).mint(account1.address)
      ).to.be.revertedWith("UdexPool: BELOW_MINIMUM_LIQUIDITY");
    });

    // tokenの入金がない状態でmintを呼んでrevertするか
    it("second mint reverted for insufficient deposit", async function () {
      const { account0, account1, account2, pool, token0, token1 } =
        await loadFixture(deployPoolFixture);
      const token0Amount = 40000;
      const token1Amount = 90000;
      const liquidity = Math.sqrt(token0Amount * token1Amount);
      await token0.transfer(pool.address, token0Amount);
      await token1.transfer(pool.address, token1Amount);
      // mintを二回呼んで2回目の方でrevertするか
      await pool.connect(account2).mint(account1.address);
      await expect(
        pool.connect(account2).mint(account1.address)
      ).to.be.revertedWith("UdexPool: INSUFFICIENT_LIQUIDITY_MINTED");
    });
  });
});
