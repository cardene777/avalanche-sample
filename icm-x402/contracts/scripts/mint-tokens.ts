import { ethers } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config({ path: "../.env" });

async function main() {
  console.log("Minting test tokens...");

  // Get deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Minting with account:", deployer.address);

  // Get token address from environment
  const ERC3009_TOKEN_ADDRESS = process.env.ERC3009_TOKEN_ADDRESS;

  if (!ERC3009_TOKEN_ADDRESS) {
    throw new Error("ERC3009_TOKEN_ADDRESS not set in .env");
  }

  // Get token contract
  const ERC3009PaymentToken = await ethers.getContractFactory("ERC3009PaymentToken");
  const token = ERC3009PaymentToken.attach(ERC3009_TOKEN_ADDRESS);

  console.log("Token address:", ERC3009_TOKEN_ADDRESS);
  console.log("Token name:", await token.name());
  console.log("Token symbol:", await token.symbol());

  // Parse command line arguments for recipient and amount
  const args = process.argv.slice(2);
  let recipient = deployer.address;
  let amount = ethers.parseUnits("1000", 6); // Default: 1000 tokens (6 decimals)

  // Parse --to argument
  const toIndex = args.indexOf("--to");
  if (toIndex !== -1 && args[toIndex + 1]) {
    recipient = args[toIndex + 1];
  }

  // Parse --amount argument
  const amountIndex = args.indexOf("--amount");
  if (amountIndex !== -1 && args[amountIndex + 1]) {
    amount = ethers.parseUnits(args[amountIndex + 1], 6);
  }

  console.log("");
  console.log("Minting:");
  console.log("  To:", recipient);
  console.log("  Amount:", ethers.formatUnits(amount, 6), "tokens");

  // Mint tokens
  const tx = await token.mint(recipient, amount);
  console.log("Transaction hash:", tx.hash);

  await tx.wait();
  console.log("✅ Tokens minted successfully!");

  // Check balance
  const balance = await token.balanceOf(recipient);
  console.log("");
  console.log("Recipient balance:", ethers.formatUnits(balance, 6), "tokens");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
