import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify"; // 🔹 Adicionando suporte para verificação no Etherscan/Arbiscan
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.26",
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11155111,
    },
    arbitrumSepolia: {
      url: `https://arb-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 421614,
    },
    sonic: {
      url: "https://rpc.blaze.soniclabs.com",
      accounts: process.env.SONIC_PRIVATE_KEY ? [process.env.SONIC_PRIVATE_KEY] : [],
    },
    luksoTestnet: {
      url: "https://rpc.testnet.lukso.network",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 4201,
    },
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY,
      arbitrumSepolia: process.env.ARBISCAN_API_KEY,
      sonic: process.env.SONIC_API_KEY,
    },
    customChains: [
      {
        network: "sonic",
        chainId: 57054,
        urls: {
          apiURL: "https://api-testnet.sonicscan.org/api",
          browserURL: "https://testnet.sonicscan.org/"
        }
      },
      {
        network: "lukso testnet",
        chainId: 4201,
        urls: {
          apiURL: "https://eth-sepolia.blockscout.com/api",
          browserURL: "https://explorer.execution.testnet.lukso.network/"
        }
      }
    ]
  },
};

export default config;
