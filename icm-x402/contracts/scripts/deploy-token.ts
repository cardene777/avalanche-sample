import { ethers } from "hardhat";

async function main() {
  console.log("Deploying ERC3009PaymentToken to Dispatch chain...");

  // Get deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // Deploy token
  const ERC3009PaymentToken = await ethers.getContractFactory("ERC3009PaymentToken");
  const token = await ERC3009PaymentToken.deploy(
    "Test USDC", // name
    "TUSDC", // symbol
    ethers.parseUnits("1000000", 6) // 1M tokens with 6 decimals
  );

  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();

  console.log("ERC3009PaymentToken deployed to:", tokenAddress);
  console.log("✅ Update .env file:");
  console.log(`ERC3009_TOKEN_ADDRESS=${tokenAddress}`);
  console.log("");
  console.log("Verifying deployment...");
  console.log("Token name:", await token.name());
  console.log("Token symbol:", await token.symbol());
  console.log("Total supply:", ethers.formatUnits(await token.totalSupply(), 6));
  console.log("Owner:", await token.owner());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
