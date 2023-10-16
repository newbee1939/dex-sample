// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import './UdexPool.sol';
import 'hardhat/console.sol';

// 指定したトークン対のアドレスから流動性プールのコントラクトを次々デプロイしていく
// デプロイされたFactoryコントラクトは唯一つ
contract UdexFactory {
    mapping(address => mapping(address => address)) public getPool;

    event PoolCreated(address indexed token0, address indexed token1, address pool);

    function createPool(address tokenA, address tokenB) external returns (address pool) {
        require(tokenA != tokenB, 'UdexFactory: IDENTICAL_TOKEN_ADDRESS');

        // アドレスの順序でsortする
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UdexFactory: ZERO_ADDRESS');
        // 既にPoolが存在しているかをチェック
        // Solidityでは、変数の値は暗に0で初期化される
        // mapping型なら登録されていないキーの値は常に0になる
        require(getPool[token0][token1] == address(0), 'UdexFactory: TOKEN_POOL_EXISTS');

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        // UdexPoolをデプロイする
        // {salt: salt} -> デプロイの際に挙動を変えるもの。トークンのペアごとにアドレスが変わる
        UdexPool poolContract = new UdexPool{salt: salt}();
        // ここでデプロイしている
        poolContract.initialize(token0, token1);

        // return文は不要
        pool = address(poolContract);
        // getPool変数にpoolのアドレスを登録する
        getPool[token0][token1] = pool;
        getPool[token1][token0] = pool;

        // ログ出力
        emit PoolCreated(token0, token1, pool);
        console.log("[Hardhat Debug] pool created at", pool);
    }
}