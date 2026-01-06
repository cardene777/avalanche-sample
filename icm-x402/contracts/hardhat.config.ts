import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@typechain/hardhat";
import * as dotenv from "dotenv";

// Load environment variables from parent directory
dotenv.config({ path: "../.env" });

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    "dispatch-testnet": {
      url: process.env.DISPATCH_RPC_URL || "",
      accounts: process.env.FACILITATOR_PRIVATE_KEY
        ? [process.env.FACILITATOR_PRIVATE_KEY]
        : [],
      chainId: 9000, // Placeholder - update with actual Dispatch testnet chain ID
    },
    "echo-testnet": {
      url: process.env.ECHO_RPC_URL || "",
      accounts: process.env.FACILITATOR_PRIVATE_KEY
        ? [process.env.FACILITATOR_PRIVATE_KEY]
        : [],
      chainId: 9001, // Placeholder - update with actual Echo testnet chain ID
    },
  },
  paths: {
    sources: "./src",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  typechain: {
    outDir: "./typechain-types",
    target: "ethers-v6",
  },
};

export default config;
