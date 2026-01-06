import { Content } from "../types/content";

/**
 * Sample paywalled content for testing
 * In production, this would be loaded from a database
 */
export const sampleContent: Content[] = [
  {
    id: "premium-guide-avalanche-icm",
    title: "Complete Guide to Avalanche Interchain Messaging",
    description:
      "Learn how to build cross-chain applications using Avalanche ICM and TeleporterMessenger. This comprehensive guide covers message passing, security best practices, and real-world examples.",
    price: BigInt("1000000000000000000"), // 1 token (18 decimals)
    provider: "0x0000000000000000000000000000000000000001", // Placeholder - update with actual provider address
    contentUrl: "https://example.com/content/premium-guide-avalanche-icm.pdf",
    preview:
      "Avalanche Interchain Messaging (ICM) enables seamless communication between L1 blockchains in the Avalanche ecosystem. This guide will teach you...",
    metadata: {
      category: "Tutorial",
      tags: ["avalanche", "icm", "cross-chain", "blockchain"],
      createdAt: Math.floor(Date.now() / 1000),
    },
  },
  {
    id: "exclusive-video-erc3009",
    title: "Mastering ERC-3009 Gasless Payments",
    description:
      "Video course on implementing ERC-3009 transferWithAuthorization for gasless payment flows. Includes code examples, security considerations, and integration patterns.",
    price: BigInt("500000000000000000"), // 0.5 tokens
    provider: "0x0000000000000000000000000000000000000001",
    contentUrl: "https://example.com/content/exclusive-video-erc3009.mp4",
    preview:
      "ERC-3009 introduces a gasless payment mechanism where users sign authorization messages off-chain, and a facilitator submits the transaction on-chain...",
    metadata: {
      category: "Video Course",
      tags: ["ethereum", "erc3009", "gasless", "payments"],
      createdAt: Math.floor(Date.now() / 1000),
    },
  },
  {
    id: "research-paper-x402",
    title: "HTTP 402 Payment Required: Modern Web Monetization",
    description:
      "Academic research paper exploring the x402 protocol for integrating blockchain payments with HTTP. Case studies, protocol design, and future directions.",
    price: BigInt("250000000000000000"), // 0.25 tokens
    provider: "0x0000000000000000000000000000000000000001",
    contentUrl: "https://example.com/content/research-paper-x402.pdf",
    preview:
      "The HTTP 402 status code has been reserved since 1997 for future payment systems. With blockchain technology, we can finally realize this vision...",
    metadata: {
      category: "Research",
      tags: ["http402", "web3", "monetization", "protocol"],
      createdAt: Math.floor(Date.now() / 1000),
    },
  },
  {
    id: "premium-template-dapp",
    title: "Full-Stack Paywall DApp Starter Template",
    description:
      "Production-ready starter template for building paywall DApps with Avalanche ICM, ERC-3009, and x402. Includes smart contracts, backend, frontend, and deployment scripts.",
    price: BigInt("2000000000000000000"), // 2 tokens
    provider: "0x0000000000000000000000000000000000000001",
    contentUrl: "https://example.com/content/premium-template-dapp.zip",
    preview:
      "This starter template includes everything you need to launch a paywall DApp: Solidity contracts for Dispatch and Echo chains, TypeScript backend with x402 implementation...",
    metadata: {
      category: "Template",
      tags: ["dapp", "template", "full-stack", "avalanche"],
      createdAt: Math.floor(Date.now() / 1000),
    },
  },
];

/**
 * Create a content store (Map) from sample data
 * @returns Map of content ID to Content
 */
export function createContentStore(): Map<string, Content> {
  const store = new Map<string, Content>();
  sampleContent.forEach((content) => {
    store.set(content.id, content);
  });
  return store;
}
