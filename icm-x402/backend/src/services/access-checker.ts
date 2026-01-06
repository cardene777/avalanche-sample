import { EchoChainClient } from "./echo-chain";
import { Content, ContentAccessStatus } from "../types/content";

/**
 * Access Checker Service
 * Checks if a buyer has access to paywalled content by querying Echo chain
 */
export class AccessChecker {
  private echoClient: EchoChainClient;
  private facilitatorUrl: string;
  private tokenAddress: string;

  constructor(
    echoClient: EchoChainClient,
    facilitatorUrl: string,
    tokenAddress: string
  ) {
    this.echoClient = echoClient;
    this.facilitatorUrl = facilitatorUrl;
    this.tokenAddress = tokenAddress;
  }

  /**
   * Check if a buyer has access to content
   * @param buyer Buyer's wallet address
   * @param content Content to check access for
   * @returns Content access status with payment requirements if needed
   */
  async checkAccess(
    buyer: string,
    content: Content
  ): Promise<ContentAccessStatus> {
    // Query Echo chain for access
    const hasAccess = await this.echoClient.hasAccess(buyer, content.id);

    // Build base response with public content info
    const baseResponse = {
      hasAccess,
      content: {
        id: content.id,
        title: content.title,
        description: content.description,
        price: content.price,
        preview: content.preview,
      },
    };

    // If user has access, include the content URL
    if (hasAccess) {
      return {
        ...baseResponse,
        contentUrl: content.contentUrl,
      };
    }

    // If no access, include payment requirements
    return {
      ...baseResponse,
      paymentRequired: {
        tokenAddress: this.tokenAddress,
        amount: content.price,
        recipient: content.provider,
        contentId: content.id,
        facilitatorUrl: this.facilitatorUrl,
      },
    };
  }

  /**
   * Bulk check access for multiple content items
   * @param buyer Buyer's wallet address
   * @param contents Array of content to check
   * @returns Map of content ID to access status
   */
  async checkBulkAccess(
    buyer: string,
    contents: Content[]
  ): Promise<Map<string, boolean>> {
    const results = new Map<string, boolean>();

    // Execute checks in parallel
    await Promise.all(
      contents.map(async (content) => {
        const hasAccess = await this.echoClient.hasAccess(buyer, content.id);
        results.set(content.id, hasAccess);
      })
    );

    return results;
  }

  /**
   * Get access grant details for a buyer and content
   * @param buyer Buyer's wallet address
   * @param contentId Content identifier
   * @returns Access grant details or null if no access
   */
  async getAccessGrant(buyer: string, contentId: string) {
    return await this.echoClient.getAccessGrant(buyer, contentId);
  }
}
