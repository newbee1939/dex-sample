import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import UdexPool from "../artifacts/contracts/UdexPool.sol/UdexPool.json";
import { ContractFactory, Contract } from "ethers";
import { getCreate2Address } from "./lib/utilities";

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
});
