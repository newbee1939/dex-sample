// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import './UdexPool.sol';
import 'hardhat/console.sol';

// 指定したトークン対のアドレスから流動性プールのコントラクトを次々デプロイしていく
// デプロイされたFactoryコントラクトは唯一つ
contract UdexFactory {
    // トークン対（トークンAとトークンBの組み合わせ）から流動性プールのアドレスを取得するための mapping 変数 
    mapping(address => mapping(address => address)) public getPool;

    // 新しい流動性プールが作成されたときに発生するイベント PoolCreated を宣言しています。このイベントは新しいプールの詳細を記録
    event PoolCreated(address indexed token0, address indexed token1, address pool);

    // 新しい流動性プールを作成するための関数
    // external と指定された関数は、コントラクトの外部から呼び出すことができます。つまり、他のスマートコントラクトやトランザクションからアクセス可能な関数
    function createPool(address tokenA, address tokenB) external returns (address pool) {
        require(tokenA != tokenB, 'UdexFactory: IDENTICAL_TOKEN_ADDRESS');

        // アドレスの順序でsortする。sortした上でtoken0とtoken1に代入する
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // 小さい方（token0）がゼロアドレスでなければ、大きい方（token1）はゼロアドレスではない
        require(token0 != address(0), 'UdexFactory: ZERO_ADDRESS');

        // 既にトークンペアの流動性Poolが存在しているかをチェック
        // Solidityでは、変数の値は暗に0で初期化される
        // mapping型なら登録されていないキーの値は常に0になる
        require(getPool[token0][token1] == address(0), 'UdexFactory: TOKEN_POOL_EXISTS');

        // abi.encodePacked(token0, token1) は、関数呼び出しの引数として渡された値を、パック（パッキング）されたバイト列に変換する Solidity のユーティリティ関数です。この場合、2つのアドレスがバイト列に変換されます。
        // keccak256(...) は、Solidityでハッシュ値を計算するための関数です。この関数は引数のバイト列に対してKECCAK-256ハッシュアルゴリズムを適用し、32バイトのハッシュ値を生成します。
        //  Keccak256関数とは？ Ethereumで使われるハッシュ関数です。
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        // UdexPoolをデプロイする
        // {salt: salt} -> デプロイの際に挙動を変えるもの。トークンのペアごとにアドレスが変わる
        // ソルトはコントラクトのアドレスを一意にするために使用されます。つまり、同じコントラクトコードを使用しても、異なるソルトを指定することで異なるアドレスにデプロイされます
        UdexPool poolContract = new UdexPool{salt: salt}();
        // ここでデプロイしている
        poolContract.initialize(token0, token1);

        // return文は不要
        pool = address(poolContract);
        // getPool変数にpoolのアドレスを登録する。二パターン登録する必要がある
        getPool[token0][token1] = pool;
        getPool[token1][token0] = pool;

        // ログ出力
        emit PoolCreated(token0, token1, pool);
        console.log("[Hardhat Debug] pool created at", pool);
    }
}