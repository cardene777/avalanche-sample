import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { EchoChainClient } from "./services/echo-chain";
import { AccessChecker } from "./services/access-checker";
import { createContentRouter } from "./api/content";
import { createContentStore } from "./data/sample-content";

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
app.use(cors({ origin: process.env.CORS_ORIGIN || "*" }));
app.use(express.json());

// Request logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Initialize services
const echoRpcUrl = process.env.ECHO_RPC_URL;
const contentAccessManagerAddress = process.env.CONTENT_ACCESS_MANAGER_ADDRESS;
const facilitatorUrl = process.env.FACILITATOR_URL;
const tokenAddress = process.env.PAYMENT_TOKEN_ADDRESS;

if (!echoRpcUrl || !contentAccessManagerAddress || !facilitatorUrl || !tokenAddress) {
  console.error("Missing required environment variables:");
  console.error("- ECHO_RPC_URL:", echoRpcUrl ? "✓" : "✗");
  console.error("- CONTENT_ACCESS_MANAGER_ADDRESS:", contentAccessManagerAddress ? "✓" : "✗");
  console.error("- FACILITATOR_URL:", facilitatorUrl ? "✓" : "✗");
  console.error("- PAYMENT_TOKEN_ADDRESS:", tokenAddress ? "✓" : "✗");
  process.exit(1);
}

// Initialize Echo chain client
const echoClient = new EchoChainClient(echoRpcUrl, contentAccessManagerAddress);

// Initialize access checker
const accessChecker = new AccessChecker(echoClient, facilitatorUrl, tokenAddress);

// Initialize content store
const contentStore = createContentStore();

// Mount API routes
app.use("/api/content", createContentRouter(accessChecker, contentStore));

// Health check endpoint
app.get("/health", async (req, res) => {
  try {
    const echoConnected = await echoClient.checkConnectivity();
    const blockNumber = echoConnected ? await echoClient.getBlockNumber() : null;

    res.json({
      status: "ok",
      timestamp: new Date().toISOString(),
      services: {
        echo: {
          connected: echoConnected,
          blockNumber,
          rpcUrl: echoRpcUrl,
        },
      },
      contentCount: contentStore.size,
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
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error("Unhandled error:", err);
  res.status(500).json({
    error: "Internal server error",
    message: process.env.NODE_ENV === "development" ? err.message : "An error occurred",
  });
});

// Start server
app.listen(PORT, () => {
  console.log("=".repeat(60));
  console.log("Backend Content Server Started");
  console.log("=".repeat(60));
  console.log(`Port: ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || "development"}`);
  console.log(`Echo RPC: ${echoRpcUrl}`);
  console.log(`Content Access Manager: ${contentAccessManagerAddress}`);
  console.log(`Facilitator URL: ${facilitatorUrl}`);
  console.log(`Content Items: ${contentStore.size}`);
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
