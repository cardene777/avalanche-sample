import { ethers } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config({ path: "../.env" });

async function main() {
  console.log("Deploying ContentAccessManager to Echo chain...");

  // Get deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // Get configuration from environment
  const ECHO_TELEPORTER_ADDRESS = process.env.ECHO_TELEPORTER_ADDRESS;
  const DISPATCH_CHAIN_ID = process.env.DISPATCH_CHAIN_ID || "0x" + "9000".toString(16).padStart(64, "0"); // Placeholder
  const PAYMENT_REGISTRY_ADDRESS = process.env.PAYMENT_REGISTRY_ADDRESS;

  if (!ECHO_TELEPORTER_ADDRESS) {
    throw new Error("ECHO_TELEPORTER_ADDRESS not set in .env");
  }
  if (!PAYMENT_REGISTRY_ADDRESS) {
    console.warn("⚠️  PAYMENT_REGISTRY_ADDRESS not set in .env");
    console.warn("⚠️  Note: You can deploy this first, then update PaymentRegistry with this address");
  }

  console.log("Configuration:");
  console.log("  TeleporterMessenger:", ECHO_TELEPORTER_ADDRESS);
  console.log("  Dispatch Chain ID:", DISPATCH_CHAIN_ID);
  console.log("  PaymentRegistry:", PAYMENT_REGISTRY_ADDRESS || "(will set later)");

  // Deploy ContentAccessManager
  const ContentAccessManager = await ethers.getContractFactory("ContentAccessManager");
  const manager = await ContentAccessManager.deploy(
    ECHO_TELEPORTER_ADDRESS,
    DISPATCH_CHAIN_ID,
    PAYMENT_REGISTRY_ADDRESS || ethers.ZeroAddress // Use zero address as placeholder
  );

  await manager.waitForDeployment();
  const managerAddress = await manager.getAddress();

  console.log("ContentAccessManager deployed to:", managerAddress);
  console.log("✅ Update .env file:");
  console.log(`CONTENT_ACCESS_MANAGER_ADDRESS=${managerAddress}`);
  console.log("");
  console.log("Verifying deployment...");
  console.log("TeleporterMessenger:", await manager.teleporterMessenger());
  console.log("Dispatch Chain ID:", await manager.dispatchChainID());
  console.log("PaymentRegistry:", await manager.paymentRegistryOnDispatch());
  console.log("Owner:", await manager.owner());
  console.log("");
  console.log("⚠️  IMPORTANT: If you haven't deployed PaymentRegistry yet:");
  console.log("   1. Update .env with this CONTENT_ACCESS_MANAGER_ADDRESS");
  console.log("   2. Deploy PaymentRegistry on Dispatch chain");
  console.log("   3. You may need to redeploy this contract with the correct PaymentRegistry address");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
