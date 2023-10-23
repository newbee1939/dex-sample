# dex-sample

DEX（分散型取引所）のサンプル

# 手順

0. 今は以下の二つが良さそう(Solidity の開発環境)
   - hardhat
   - ethers.js
1. npm init -y
2. npm install --save-dev hardhat dotenv
3. npx hardhat
   1. Create a TypeScript project
   2. 他は yes
4. 不要なファイルの削除
   1. rm contracts/Lock.sol
   2. rm scripts/deploy.ts
   3. rm test/Lock.ts
5. tsconfig で`"resolveJsonModule": true`を追加
   - JSON ファイルを読み込めるようにするため
6. hardhat.config.ts
   - 必要に応じて hardhat の設定を書く
7. Solidity コントラクトの実装に入る
8. npx hardhat compile でコンパイル -> artifacts ファイルが作成される
9. 動作担保のためのユニットテストを書く
   - code test/UdexFactory.ts
10. npx hardhat test で実行できる

# メモ

- UdexPool コントラクトの概要
  - UdexPool には以下の 3 つの関数を実装する
  - mint
    - トークン対を預け入れて流動性トークンを発行する
  - burn
    - 流動性トークンを burn するとトークン対が引き出せる
  - swap
    - トークンの交換を行う（AMM がレートを定める）
    - 手数料 0.3%

# 資料

- .png ファイル
- 作成する DEX のデモと全体像
  - https://www.udemy.com/course/web3dapps/learn/lecture/36128736#overview
- 作成するコントラクトの概要
  - https://www.udemy.com/course/web3dapps/learn/lecture/36130152#overview
