import { ethers } from "ethers";

/**
 * Dispatch Chain RPC Client
 * Provides methods to interact with Dispatch L1 testnet
 */
export class DispatchChainClient {
  private provider: ethers.JsonRpcProvider;
  private paymentTokenAddress: string;
  private paymentRegistryAddress: string;
  private paymentTokenABI: string[];
  private paymentRegistryABI: string[];

  constructor(
    rpcUrl: string,
    paymentTokenAddress: string,
    paymentRegistryAddress: string
  ) {
    this.provider = new ethers.JsonRpcProvider(rpcUrl);
    this.paymentTokenAddress = paymentTokenAddress;
    this.paymentRegistryAddress = paymentRegistryAddress;

    // ERC3009PaymentToken ABI (minimal - only needed methods)
    this.paymentTokenABI = [
      "function transferWithAuthorization(address from, address to, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) external",
      "function authorizationState(address authorizer, bytes32 nonce) external view returns (bool)",
      "function balanceOf(address account) external view returns (uint256)",
      "function DOMAIN_SEPARATOR() external view returns (bytes32)",
    ];

    // PaymentRegistry ABI (minimal - only needed methods)
    this.paymentRegistryABI = [
      "function settlePayment(address buyer, bytes32 contentId, uint256 amount, bytes32 paymentTxHash) external",
      "function payments(address buyer, bytes32 contentId) external view returns (tuple(address buyer, bytes32 contentId, uint256 amount, bytes32 paymentTxHash, uint256 settledAt))",
    ];
  }

  /**
   * Get PaymentToken contract instance
   */
  private getPaymentTokenContract(signer?: ethers.Signer): ethers.Contract {
    return new ethers.Contract(
      this.paymentTokenAddress,
      this.paymentTokenABI,
      signer || this.provider
    );
  }

  /**
   * Get PaymentRegistry contract instance
   */
  private getPaymentRegistryContract(
    signer?: ethers.Signer
  ): ethers.Contract {
    return new ethers.Contract(
      this.paymentRegistryAddress,
      this.paymentRegistryABI,
      signer || this.provider
    );
  }

  /**
   * Execute transferWithAuthorization (ERC-3009 gasless transfer)
   * @param from Buyer's address (token owner)
   * @param to Recipient address (usually content provider)
   * @param value Amount to transfer
   * @param validAfter Timestamp after which the authorization is valid
   * @param validBefore Timestamp before which the authorization is valid
   * @param nonce Unique nonce for this authorization
   * @param signature EIP-712 signature from buyer (v, r, s components)
   * @param signer Facilitator's wallet (pays gas)
   * @returns Transaction receipt
   */
  async transferWithAuthorization(
    from: string,
    to: string,
    value: bigint,
    validAfter: bigint,
    validBefore: bigint,
    nonce: string,
    signature: { v: number; r: string; s: string },
    signer: ethers.Signer
  ): Promise<ethers.TransactionReceipt> {
    const contract = this.getPaymentTokenContract(signer);

    const tx = await contract.transferWithAuthorization(
      from,
      to,
      value,
      validAfter,
      validBefore,
      nonce,
      signature.v,
      signature.r,
      signature.s
    );

    return await tx.wait();
  }

  /**
   * Check if an authorization nonce has been used
   * @param authorizer Address of the token owner
   * @param nonce The nonce to check
   * @returns True if nonce has been used
   */
  async isNonceUsed(authorizer: string, nonce: string): Promise<boolean> {
    const contract = this.getPaymentTokenContract();
    return await contract.authorizationState(authorizer, nonce);
  }

  /**
   * Get token balance of an address
   * @param address Address to query
   * @returns Token balance
   */
  async getBalance(address: string): Promise<bigint> {
    const contract = this.getPaymentTokenContract();
    return await contract.balanceOf(address);
  }

  /**
   * Get EIP-712 domain separator for the payment token
   * @returns Domain separator bytes32
   */
  async getDomainSeparator(): Promise<string> {
    const contract = this.getPaymentTokenContract();
    return await contract.DOMAIN_SEPARATOR();
  }

  /**
   * Settle payment in PaymentRegistry (owner-only function)
   * @param buyer Buyer's address
   * @param contentId Content identifier (string will be hashed to bytes32)
   * @param amount Payment amount
   * @param paymentTxHash Transaction hash of the payment
   * @param signer Registry owner's wallet
   * @returns Transaction receipt
   */
  async settlePayment(
    buyer: string,
    contentId: string,
    amount: bigint,
    paymentTxHash: string,
    signer: ethers.Signer
  ): Promise<ethers.TransactionReceipt> {
    const contract = this.getPaymentRegistryContract(signer);
    const contentIdHash = ethers.id(contentId); // keccak256 hash

    const tx = await contract.settlePayment(
      buyer,
      contentIdHash,
      amount,
      paymentTxHash
    );

    return await tx.wait();
  }

  /**
   * Get payment record from PaymentRegistry
   * @param buyer Buyer's address
   * @param contentId Content identifier (string will be hashed to bytes32)
   * @returns Payment record or null if not found
   */
  async getPaymentRecord(buyer: string, contentId: string): Promise<{
    buyer: string;
    contentId: string;
    amount: bigint;
    paymentTxHash: string;
    settledAt: bigint;
  } | null> {
    try {
      const contract = this.getPaymentRegistryContract();
      const contentIdHash = ethers.id(contentId);
      const payment = await contract.payments(buyer, contentIdHash);

      // Check if payment exists (settledAt > 0)
      if (payment.settledAt === 0n) {
        return null;
      }

      return {
        buyer: payment.buyer,
        contentId: ethers.hexlify(payment.contentId),
        amount: payment.amount,
        paymentTxHash: payment.paymentTxHash,
        settledAt: payment.settledAt,
      };
    } catch (error) {
      console.error("Error fetching payment record:", error);
      return null;
    }
  }

  /**
   * Get current block number
   * @returns Current block number on Dispatch chain
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
      console.error("Dispatch chain RPC connection failed:", error);
      return false;
    }
  }
}
