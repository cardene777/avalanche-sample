import { ethers } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config({ path: "../.env" });

async function main() {
  console.log("Deploying PaymentRegistry to Dispatch chain...");

  // Get deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // Get configuration from environment
  const DISPATCH_TELEPORTER_ADDRESS = process.env.DISPATCH_TELEPORTER_ADDRESS;
  const ECHO_CHAIN_ID = process.env.ECHO_CHAIN_ID || "0x" + "9001".toString(16).padStart(64, "0"); // Placeholder
  const CONTENT_ACCESS_MANAGER_ADDRESS = process.env.CONTENT_ACCESS_MANAGER_ADDRESS;

  if (!DISPATCH_TELEPORTER_ADDRESS) {
    throw new Error("DISPATCH_TELEPORTER_ADDRESS not set in .env");
  }
  if (!CONTENT_ACCESS_MANAGER_ADDRESS) {
    console.warn("⚠️  CONTENT_ACCESS_MANAGER_ADDRESS not set in .env");
    console.warn("⚠️  You must deploy ContentAccessManager on Echo first and update .env");
    throw new Error("CONTENT_ACCESS_MANAGER_ADDRESS required");
  }

  console.log("Configuration:");
  console.log("  TeleporterMessenger:", DISPATCH_TELEPORTER_ADDRESS);
  console.log("  Echo Chain ID:", ECHO_CHAIN_ID);
  console.log("  ContentAccessManager:", CONTENT_ACCESS_MANAGER_ADDRESS);

  // Deploy PaymentRegistry
  const PaymentRegistry = await ethers.getContractFactory("PaymentRegistry");
  const registry = await PaymentRegistry.deploy(
    DISPATCH_TELEPORTER_ADDRESS,
    ECHO_CHAIN_ID,
    CONTENT_ACCESS_MANAGER_ADDRESS
  );

  await registry.waitForDeployment();
  const registryAddress = await registry.getAddress();

  console.log("PaymentRegistry deployed to:", registryAddress);
  console.log("✅ Update .env file:");
  console.log(`PAYMENT_REGISTRY_ADDRESS=${registryAddress}`);
  console.log("");
  console.log("Verifying deployment...");
  console.log("TeleporterMessenger:", await registry.teleporterMessenger());
  console.log("Echo Chain ID:", await registry.echoChainID());
  console.log("ContentAccessManager:", await registry.contentAccessManagerOnEcho());
  console.log("Owner:", await registry.owner());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
