/**
 * Content Entity
 * Represents paywalled content in the system
 */
export interface Content {
  /**
   * Unique content identifier (will be hashed to bytes32 for on-chain use)
   */
  id: string;

  /**
   * Content title
   */
  title: string;

  /**
   * Content description
   */
  description: string;

  /**
   * Price in payment token (smallest unit, e.g., wei-equivalent)
   */
  price: bigint;

  /**
   * Content provider's address (receives payment)
   */
  provider: string;

  /**
   * URL to the actual content (only accessible after payment)
   */
  contentUrl: string;

  /**
   * Preview text or data (publicly accessible)
   */
  preview?: string;

  /**
   * Content metadata (optional)
   */
  metadata?: {
    category?: string;
    tags?: string[];
    createdAt?: number;
    updatedAt?: number;
  };
}

/**
 * Content access status
 */
export interface ContentAccessStatus {
  /**
   * Whether the buyer has access to this content
   */
  hasAccess: boolean;

  /**
   * Content details (always included)
   */
  content: Pick<Content, "id" | "title" | "description" | "price" | "preview">;

  /**
   * Full content URL (only included if hasAccess is true)
   */
  contentUrl?: string;

  /**
   * Payment requirement details (only included if hasAccess is false)
   */
  paymentRequired?: {
    /**
     * Payment token contract address on Dispatch chain
     */
    tokenAddress: string;

    /**
     * Amount required (in token's smallest unit)
     */
    amount: bigint;

    /**
     * Recipient address (content provider)
     */
    recipient: string;

    /**
     * Content ID (for payment reference)
     */
    contentId: string;

    /**
     * Facilitator endpoint for submitting payment authorization
     */
    facilitatorUrl: string;
  };
}

/**
 * Payment authorization request (from buyer to facilitator)
 */
export interface PaymentAuthorizationRequest {
  /**
   * Buyer's wallet address
   */
  from: string;

  /**
   * Content provider's address (recipient)
   */
  to: string;

  /**
   * Payment amount
   */
  value: string; // bigint as string for JSON serialization

  /**
   * Valid after timestamp
   */
  validAfter: string; // bigint as string

  /**
   * Valid before timestamp
   */
  validBefore: string; // bigint as string

  /**
   * Unique nonce
   */
  nonce: string; // bytes32 as hex string

  /**
   * EIP-712 signature components
   */
  signature: {
    v: number;
    r: string; // bytes32 as hex string
    s: string; // bytes32 as hex string
  };

  /**
   * Content ID (for reference)
   */
  contentId: string;
}
