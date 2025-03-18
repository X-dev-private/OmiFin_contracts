import { ethers } from "hardhat";
import fs from "fs";

// Função para deploy do TokenFactory
async function deployTokenFactory(owner: string) {
  console.log("🚀 Implantando TokenFactory...");

  const TokenFactory = await ethers.getContractFactory("TokenFactory");
  const tokenFactory = await TokenFactory.deploy();
  await tokenFactory.waitForDeployment();

  const address = await tokenFactory.getAddress();
  console.log(`✅ TokenFactory implantado em: ${address}`);

  return address;
}

// Função principal
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`👤 Deploy sendo feito pelo endereço: ${deployer.address}`);

  // Deploy do TokenFactory
  const tokenFactoryAddress = await deployTokenFactory(deployer.address);

  // Salva o endereço no arquivo JSON
  const addresses = { TokenFactory: tokenFactoryAddress };
  fs.writeFileSync("deployed-addresses.json", JSON.stringify(addresses, null, 2));

  console.log("📁 Endereços salvos em deployed-addresses.json");
}

// Executa o script
main().catch((error) => {
  console.error("❌ Erro ao implantar contrato:", error);
  process.exitCode = 1;
});
