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

  // Configure manualmente os endereços dos tokens
  const tokenAAddress = "0x32c00bD194B3ea78B9799394984DF8dB7397B834"; 
  const tokenBAddress = "0x1429c6F2Be05EFF1fB07F52D9D4880a108153dD4"; 

  // Deploy do contrato de swap
  const LiquidityPool = await ethers.getContractFactory("SimpleLiquidityPool");
  const pool = await LiquidityPool.deploy(
    tokenAAddress,
    tokenBAddress,
    deployer.address
  );

  await pool.waitForDeployment();
  const poolAddress = await pool.getAddress();

  // Salvar com formatação personalizada
  const deploymentInfo = {
    network: (await ethers.provider.getNetwork()).chainId.toString(),
    poolAddress: poolAddress,
    tokenA: tokenAAddress,
    tokenB: tokenBAddress,
    deployer: deployer.address
  };

  fs.writeFileSync(
    "deployment.json",
    JSON.stringify(deploymentInfo, replacer, 2)
  );

  console.log("✅ Swap implantado:", poolAddress);
}

main().catch(console.error);