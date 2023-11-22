# dex-sample

DEX（分散型取引所）のサンプルアプリケーション

# 概要

- 作成する DEX のデモと全体像
  - https://www.udemy.com/course/web3dapps/learn/lecture/36128736#overview
- 作成するコントラクトの概要
  - https://www.udemy.com/course/web3dapps/learn/lecture/36130152#overview

# 開発手順

0. 今は以下の二つが良いらしい(Solidity の開発環境)
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

# アプリケーションの処理の流れ

1.

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
- 「実行がアトミックである」
  - Solidity のコントラクトの関数は全て実行されるか全くされないかの二択
  - このことを「実行がアトミックである」と言うらしい(それ以上分割されないということ)

# 資料

- .png ファイル
- 作成する DEX のデモと全体像
  - https://www.udemy.com/course/web3dapps/learn/lecture/36128736#overview
- 作成するコントラクトの概要
  - https://www.udemy.com/course/web3dapps/learn/lecture/36130152#overview

# タスク

- 全てのコードを理解する
- 色々コードを変えてみて挙動を確かめる
- アプリが動作するところまで作り切る

# その他
