# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.ts
```

contract address sonic : 

"USDCoFToken": "0x911aE2B3C1D6Fe71C6B19938922faa8AbDdc035c",
"ETHoFToken": "0x15F3DF98AC835D5661F791D8877C2cD7f6A4B876",
"AnJuXToken": "0x0c5aAE3d2166F20995f63F48b897E425a804CaDD"

arbitrum sepolia :

"USDCoFToken": "0xD9BEF40A259Cc6458457313438d9deb1D74fbfD5",
"ETHoFToken": "0x32c00bD194B3ea78B9799394984DF8dB7397B834",
"AnJuXToken": "0x1429c6F2Be05EFF1fB07F52D9D4880a108153dD4"

contract address sepolia :

USDCoFToken: 0x32c00bD194B3ea78B9799394984DF8dB7397B834
ETHoFToken: 0x1429c6F2Be05EFF1fB07F52D9D4880a108153dD4
AnJuXToken: 0x6c3aaaA93CC59f5A4288465F073C2B94DDBD3a05

confirm address sepolia : 

npx hardhat verify --network sepolia 0x6c3aaaA93CC59f5A4288465F073C2B94DDBD3a05
