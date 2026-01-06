import { ethers } from "ethers";

/**
 * Echo Chain RPC Client
 * Provides methods to interact with Echo L1 testnet
 */
export class EchoChainClient {
  private provider: ethers.JsonRpcProvider;
  private contentAccessManagerAddress: string;
  private contentAccessManagerABI: string[];

  constructor(rpcUrl: string, contentAccessManagerAddress: string) {
    this.provider = new ethers.JsonRpcProvider(rpcUrl);
    this.contentAccessManagerAddress = contentAccessManagerAddress;

    // ContentAccessManager ABI (minimal - only needed methods)
    this.contentAccessManagerABI = [
      "function hasAccess(address buyer, bytes32 contentId) external view returns (bool)",
      "function access(address buyer, bytes32 contentId) external view returns (bool)",
      "function getAccessGrant(address buyer, bytes32 contentId) external view returns (tuple(address buyer, bytes32 contentId, uint256 amount, bytes32 paymentTxHash, uint256 grantedAt))",
    ];
  }

  /**
   * Get ContentAccessManager contract instance
   */
  private getContract(): ethers.Contract {
    return new ethers.Contract(
      this.contentAccessManagerAddress,
      this.contentAccessManagerABI,
      this.provider
    );
  }

  /**
   * Check if a buyer has access to content
   * @param buyer Buyer's wallet address
   * @param contentId Content identifier (string will be hashed to bytes32)
   * @returns True if buyer has access
   */
  async hasAccess(buyer: string, contentId: string): Promise<boolean> {
    const contract = this.getContract();
    const contentIdHash = ethers.id(contentId); // keccak256 hash
    const hasAccess = await contract.hasAccess(buyer, contentIdHash);
    return hasAccess;
  }

  /**
   * Get access grant details for a buyer and content
   * @param buyer Buyer's wallet address
   * @param contentId Content identifier (string will be hashed to bytes32)
   * @returns Access grant details or null if no access
   */
  async getAccessGrant(buyer: string, contentId: string): Promise<{
    buyer: string;
    contentId: string;
    amount: bigint;
    paymentTxHash: string;
    grantedAt: bigint;
  } | null> {
    try {
      const contract = this.getContract();
      const contentIdHash = ethers.id(contentId);
      const grant = await contract.getAccessGrant(buyer, contentIdHash);

      // Check if grant exists (grantedAt > 0)
      if (grant.grantedAt === 0n) {
        return null;
      }

      return {
        buyer: grant.buyer,
        contentId: ethers.hexlify(grant.contentId),
        amount: grant.amount,
        paymentTxHash: grant.paymentTxHash,
        grantedAt: grant.grantedAt,
      };
    } catch (error) {
      console.error("Error fetching access grant:", error);
      return null;
    }
  }

  /**
   * Get current block number
   * @returns Current block number on Echo chain
   */
  async getBlockNumber(): Promise<number> {
    return await this.provider.getBlockNumber();
  }

  /**
   * Check RPC connectivity
   * @returns True if RPC is accessible
   */
  async checkConnectivity(): Promise<boolean> {
    try {
      await this.provider.getBlockNumber();
      return true;
    } catch (error) {
      console.error("Echo chain RPC connection failed:", error);
      return false;
    }
  }
}
