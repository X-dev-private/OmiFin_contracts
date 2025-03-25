import { ethers } from "hardhat";
import fs from "fs";

// Função para serializar BigInt
function replacer(key: any, value: any) {
  if (typeof value === 'bigint') {
    return value.toString();
  }
  return value;
}

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Conta do deploy:", deployer.address);

  // Deploy do contrato Factory
  const PoolFactory = await ethers.getContractFactory("PoolFactory");
  const factory = await PoolFactory.deploy();
  
  await factory.waitForDeployment();
  const factoryAddress = await factory.getAddress();

  // Salvar com formatação personalizada
  const deploymentInfo = {
    network: (await ethers.provider.getNetwork()).chainId.toString(),
    factoryAddress: factoryAddress,
    deployer: deployer.address
  };

  fs.writeFileSync(
    "deployment.json",
    JSON.stringify(deploymentInfo, replacer, 2)
  );

  console.log("✅ PoolFactory implantado:", factoryAddress);
  console.log("Use a função createPool() para criar novos pools de liquidez");
}

main().catch(console.error);