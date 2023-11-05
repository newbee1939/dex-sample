import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import UdexPool from "../artifacts/contracts/UdexPool.sol/UdexPool.json";
import { ContractFactory, Contract } from "ethers";
import { getCreate2Address } from "./lib/utilities";

// "0x" から始まり、40文字の16進数で構成される必要がある
// トークンペアの仮想的なアドレス
const TEST_TOKEN_ADDRESSES: [string, string] = [
  "0x1234000000000000000000000000000000000000",
  "0x3456000000000000000000000000000000000000",
];
// hardhat networkという、イーサリアムを模したテストネットワークが使われる
describe("UdexFactory", () => {
  // 一般的に、フィクスチャ関数はテストフレームワーク（例: Mocha、Jest、pytestなど）内で使用され、
  // テストケースの前処理や初期化を行うために呼び出されます。フィクスチャ関数はテストスイート内で
  // 1回または複数回呼び出すことができ、テストスイート内の複数のテストケースで同じ初期化を共有するために使用されます
  async function deployFactoryFixture() {
    // UdexFactoryの情報を読み込む
    // EthereumのスマートコントラクトファクトリーであるUdexFactoryの情報を読み込みます。ethersライブラリのgetContractFactory関数は、指定したスマートコントラクトのABI（Application Binary Interface）情報を読み込み、コントラクトファクトリーを作成します
    const Factory: ContractFactory = await ethers.getContractFactory(
      "UdexFactory"
    );
    // コントラクトをデプロイするというトランザクションの情報をイーサリアムネットワークに送る
    const factory: Contract = await Factory.deploy();
    // コントラクトの情報がイーサリアム上に書き込まれたことを確認する
    // この行は、デプロイが完了するまで待機します。
    await factory.deployed();
    return { factory };
  }

  it("get no pool address before creation", async () => {
    const { factory } = await loadFixture(deployFactoryFixture);
    expect(await factory.getPool(...TEST_TOKEN_ADDRESSES)).to.eq(
      ethers.constants.AddressZero
    );
  });

  // ここから
  it("get pool address after creation", async () => {
    const { factory } = await loadFixture(deployFactoryFixture);
    // イーサリアムノードにトランザクションを送信する
    // 戻り値としてpoolのアドレス値は返ってこない
    const tx = await factory.createPool(...TEST_TOKEN_ADDRESSES);
    // 処理中に発行されたEventはレシートに書き込まれる
    const receipt = await tx.wait();
    const event = factory.interface.parseLog(receipt.logs[0]);
    expect(event.name).to.eq("PoolCreated");
    const poolAddress: string = event.args[2];
    // poolのアドレスがmappingのstorgeに書き込まれたことをテスト
    expect(
      await factory.getPool(TEST_TOKEN_ADDRESSES[1], TEST_TOKEN_ADDRESSES[0])
    ).to.eq(poolAddress);
    expect(
      await factory.getPool(TEST_TOKEN_ADDRESSES[0], TEST_TOKEN_ADDRESSES[1])
    ).to.eq(poolAddress);
  });

  it("pool created at expected address", async () => {
    const { factory } = await loadFixture(deployFactoryFixture);
    const bytecode: string = UdexPool.bytecode;
    const [address0, address1] =
      TEST_TOKEN_ADDRESSES[0] < TEST_TOKEN_ADDRESSES[1]
        ? TEST_TOKEN_ADDRESSES
        : [TEST_TOKEN_ADDRESSES[0], TEST_TOKEN_ADDRESSES[1]];
    // デプロイアドレスを取得する
    const create2Address = getCreate2Address(
      factory.address,
      [address0, address1],
      bytecode
    );

    // to.emitでEventが出ていることをテスト
    await expect(factory.createPool(...TEST_TOKEN_ADDRESSES))
      .to.emit(factory, "PoolCreated")
      .withArgs(address0, address1, create2Address);
  });
});
