import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { ethers } from "ethers";
import { DispatchChainClient } from "./services/dispatch-chain";
import { PaymentExecutor } from "./services/payment-executor";
import { PaymentSettler } from "./services/payment-settler";
import { createPaymentRouter } from "./api/payment";

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors({ origin: process.env.CORS_ORIGIN || "*" }));
app.use(express.json());

// Request logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Initialize services
const dispatchRpcUrl = process.env.DISPATCH_RPC_URL;
const paymentTokenAddress = process.env.PAYMENT_TOKEN_ADDRESS;
const paymentRegistryAddress = process.env.PAYMENT_REGISTRY_ADDRESS;
const facilitatorPrivateKey = process.env.FACILITATOR_PRIVATE_KEY;

// Environment variable validation
if (
  !dispatchRpcUrl ||
  !paymentTokenAddress ||
  !paymentRegistryAddress ||
  !facilitatorPrivateKey
) {
  console.error("Missing required environment variables:");
  console.error("- DISPATCH_RPC_URL:", dispatchRpcUrl ? "✓" : "✗");
  console.error(
    "- PAYMENT_TOKEN_ADDRESS:",
    paymentTokenAddress ? "✓" : "✗"
  );
  console.error(
    "- PAYMENT_REGISTRY_ADDRESS:",
    paymentRegistryAddress ? "✓" : "✗"
  );
  console.error(
    "- FACILITATOR_PRIVATE_KEY:",
    facilitatorPrivateKey ? "✓" : "✗"
  );
  process.exit(1);
}

// Initialize Dispatch chain client
const dispatchClient = new DispatchChainClient(
  dispatchRpcUrl,
  paymentTokenAddress,
  paymentRegistryAddress
);

// Initialize provider for facilitator wallet
const provider = new ethers.JsonRpcProvider(dispatchRpcUrl);

// Initialize payment executor
const paymentExecutor = new PaymentExecutor(
  dispatchClient,
  facilitatorPrivateKey,
  provider
);

// Initialize payment settler
const paymentSettler = new PaymentSettler(
  dispatchClient,
  facilitatorPrivateKey,
  provider
);

// Mount API routes
app.use("/api/payment", createPaymentRouter(paymentExecutor, paymentSettler));

// Health check endpoint
app.get("/health", async (req, res) => {
  try {
    const dispatchConnected = await dispatchClient.checkConnectivity();
    const blockNumber = dispatchConnected
      ? await dispatchClient.getBlockNumber()
      : null;
    const facilitatorAddress = paymentExecutor.getAddress();
    const facilitatorBalance = await paymentExecutor.getBalance();

    res.json({
      status: "ok",
      timestamp: new Date().toISOString(),
      services: {
        dispatch: {
          connected: dispatchConnected,
          blockNumber,
          rpcUrl: dispatchRpcUrl,
        },
      },
      wallet: {
        address: facilitatorAddress,
        balance: ethers.formatEther(facilitatorBalance),
      },
    });
  } catch (error) {
    res.status(500).json({
      status: "error",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: "Not found",
    message: `Route ${req.method} ${req.path} not found`,
  });
});

// Error handler
app.use(
  (
    err: Error,
    req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ) => {
    console.error("Unhandled error:", err);
    res.status(500).json({
      error: "Internal server error",
      message: process.env.NODE_ENV === "development" ? err.message : "An error occurred",
    });
  }
);

// Start server
app.listen(PORT, () => {
  console.log("=".repeat(60));
  console.log("Facilitator Payment Service Started");
  console.log("=".repeat(60));
  console.log(`Port: ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || "development"}`);
  console.log(`Dispatch RPC: ${dispatchRpcUrl}`);
  console.log(`Payment Token: ${paymentTokenAddress}`);
  console.log(`Payment Registry: ${paymentRegistryAddress}`);
  console.log(`Facilitator Address: ${paymentExecutor.getAddress()}`);
  console.log("=".repeat(60));
});

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM received, shutting down gracefully...");
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("SIGINT received, shutting down gracefully...");
  process.exit(0);
});
