import { ethers } from "hardhat";
import fs from "fs";

// Função para deploy de um token
async function deployToken(name: string, feeReceiver: string) {
  console.log(`Deploying ${name}...`);

  const Token = await ethers.getContractFactory(name);
  const token = await Token.deploy(feeReceiver); // Passa o endereço do feeReceiver
  await token.waitForDeployment();

  const address = await token.getAddress(); // Obtém o endereço do contrato
  console.log(`${name} deployed at: ${address}`);

  return address;
}

// Função principal
async function main() {
  // Defina o endereço que receberá as taxas (feeReceiver)
  const feeReceiver = "0x76FD1f5839572eeDc0bab748E98301f3Ae18a91F"; // Substitua pelo endereço da carteira que receberá as taxas

  console.log("Iniciando o deploy dos contratos...");

  // Faz o deploy dos contratos sequencialmente
  const usdCoF = await deployToken("USDCoFToken", feeReceiver);
  const ETHoF = await deployToken("ETHoFToken", feeReceiver);
  const AnJuX = await deployToken("AnJuXToken", feeReceiver);

  // Salva os endereços dos contratos em um arquivo JSON
  const addresses = {
    USDCoFToken: usdCoF,
    ETHoFToken: ETHoF,
    AnJuXToken: AnJuX,
  };
  fs.writeFileSync("deployed-addresses.json", JSON.stringify(addresses, null, 2));

  console.log("Todos os contratos foram implantados:");
  console.log(`USDCoFToken: ${usdCoF}`);
  console.log(`ETHoFToken: ${ETHoF}`);
  console.log(`AnJuXToken: ${AnJuX}`);
}

// Executa o script
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});