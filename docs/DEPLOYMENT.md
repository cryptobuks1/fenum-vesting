
## Деплой
Для создания новой сид фразы при деплое из терминала:
```bash
yarn run mnemonic
```


### Деплой Remix
  - Переключить MetaMask в нужную сеть;
  - Пополнить баланс;
  - Открыть сайт [http://remix.ethereum.org/](http://remix.ethereum.org/);
  - Создать в Remix файл `FenumVesting.sol` и скопировать в него содержимое файла `contracts/FenumVesting.sol`;
  - Компиляция:
    - `COMPILER`: `0.7.6`;
    - `Enable optimization`: `true`;
    - `runs`: с `200` на `999999`;
    - Нажать кнопку `Compile FenumVesting.sol`.
  - Деплой:
    - `ENVIRONMENT`: `Injected Web3` (появится адрес и баланс из `MetaMask`);
    - `CONTRACT`: `FenumVesting - browser/FenumVesting.sol`;
    - Указать параметры:
      - Адрес `FenumToken` (TOKEN_ADDRESS);
      - Время начала вестинга в секундах UTC;
      - Время конца вестинга в секундах UTC;
      - Время запрета на первое снятие в секундах.
    - Нажать кнопку `Deploy`.
  - Верификация контракта на `Etherscan`:
    - Открыть контракт во вкладке `Contract`;
    - Нажать `Verify and Publish`;
    - `Please select Compiler Type`: `Solidity (Single file)`;
    - `Please select Compiler Version`: `v0.7.6`;
    - `Please select Open Source License Type`: `MIT License (MIT)`;
    - `Continue`;
    - `Optimization`: `Yes`;
    - Вставить код контракта `FenumVesting.sol` в поле `Enter the Solidity Contract Code below *`;
    - Открыть `(Runs, EvmVersion & License Type settings)`;
    - `Runs`: `999999`;
    - Нажать `Verify and Publish`.
  - Добавление получателей в вестинг:
    - В контракте `FenumToken` cделать `approve` на адрес `FenumVesting` (в MetaMask или Etherscan) в точном количестве FNM которые предназанчены для получателя (!децимал помним);
    - В контракте `FenumVesting` cделать `createVestingSchedule` (в MetaMask или Etherscan): адрес получателя и количество FNM (!децимал помним);



### Деплой Development
В отдельном терминале запустить `ganache-cli`:
```bash
yarn run ganache-cli
```

После этого деплой:
```bash
yarn run deploy development
```


### Деплой Mainnet
```bash
yarn run deploy mainnet
yarn run verify mainnet FenumVesting
```


### Деплой Ropsten
```bash
yarn run deploy ropsten
yarn run verify ropsten FenumVesting
```


### Деплой Kovan
```bash
yarn run deploy kovan
yarn run verify kovan FenumVesting
```


### Деплой Rinkeby
```bash
yarn run deploy rinkeby
yarn run verify rinkeby FenumVesting
```


### Деплой Goerli
```bash
yarn run deploy goerli
yarn run verify goerli FenumVesting
```


### Публикация в NPM
После деплоя нужно опубликовать в [NPM](https://www.npmjs.com/).
```bash
npm publish
# или
yarn publish
```
