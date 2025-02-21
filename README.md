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

contract address :

USDCoFToken: 0x32c00bD194B3ea78B9799394984DF8dB7397B834
ETHoFToken: 0x1429c6F2Be05EFF1fB07F52D9D4880a108153dD4
AnJuXToken: 0x6c3aaaA93CC59f5A4288465F073C2B94DDBD3a05

confirm address : 

npx hardhat verify --network sepolia 0x6c3aaaA93CC59f5A4288465F073C2B94DDBD3a05
