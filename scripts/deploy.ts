import { ethers } from "hardhat";

async function deployToken(name: string) {
  console.log(`Deploying ${name}...`);

  const Token = await ethers.getContractFactory(name);
  const token = await Token.deploy();
  await token.waitForDeployment(); // Correção aqui ✅

  const address = await token.getAddress(); // Ethers v6 exige isso para pegar o endereço

  console.log(`${name} deployed at: ${address}`);
  return address;
}

async function main() {
  const usdCoF = await deployToken("USDCoFToken");
  const ETHoF = await deployToken("ETHoFToken");
  const AnJuX = await deployToken("AnJuXToken");

  console.log("Todos os contratos foram implantados:");
  console.log(`USDCoFToken: ${usdCoF}`);
  console.log(`ETHoFToken: ${ETHoF}`);
  console.log(`AnJuXToken: ${AnJuX}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
