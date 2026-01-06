import { Router, Request, Response } from "express";
import { AccessChecker } from "../services/access-checker";
import { Content } from "../types/content";

/**
 * Content API Router
 * Implements x402 protocol for paywalled content access
 */
export function createContentRouter(
  accessChecker: AccessChecker,
  contentStore: Map<string, Content>
): Router {
  const router = Router();

  /**
   * GET /api/content/:id
   * Access paywalled content with x402 protocol
   *
   * Headers:
   *   - X-BUYER-ADDRESS: Buyer's wallet address (required)
   *
   * Responses:
   *   - 200: Content accessible, returns content URL
   *   - 402: Payment Required, returns payment details in X-PAYMENT header
   *   - 400: Bad Request (missing buyer address)
   *   - 404: Content not found
   */
  router.get("/:id", async (req: Request, res: Response) => {
    try {
      const contentId = req.params.id;
      const buyerAddress = req.headers["x-buyer-address"] as string;

      // Validate buyer address
      if (!buyerAddress) {
        return res.status(400).json({
          error: "Missing X-BUYER-ADDRESS header",
          message: "Buyer wallet address is required",
        });
      }

      // Validate Ethereum address format
      if (!/^0x[a-fA-F0-9]{40}$/.test(buyerAddress)) {
        return res.status(400).json({
          error: "Invalid buyer address",
          message: "X-BUYER-ADDRESS must be a valid Ethereum address",
        });
      }

      // Fetch content from store
      const content = contentStore.get(contentId);
      if (!content) {
        return res.status(404).json({
          error: "Content not found",
          message: `No content found with id: ${contentId}`,
        });
      }

      // Check access on Echo chain
      const accessStatus = await accessChecker.checkAccess(
        buyerAddress,
        content
      );

      // If user has access, return 200 with content
      if (accessStatus.hasAccess) {
        return res.status(200).json({
          id: content.id,
          title: content.title,
          description: content.description,
          contentUrl: accessStatus.contentUrl,
          metadata: content.metadata,
        });
      }

      // If no access, return 402 with payment requirements
      // x402 protocol: Set X-PAYMENT header with payment details
      const paymentDetails = JSON.stringify({
        tokenAddress: accessStatus.paymentRequired!.tokenAddress,
        amount: accessStatus.paymentRequired!.amount.toString(), // bigint to string
        recipient: accessStatus.paymentRequired!.recipient,
        contentId: accessStatus.paymentRequired!.contentId,
        facilitatorUrl: accessStatus.paymentRequired!.facilitatorUrl,
      });

      res.setHeader("X-PAYMENT", paymentDetails);
      return res.status(402).json({
        error: "Payment Required",
        message: "You need to pay to access this content",
        content: {
          id: accessStatus.content.id,
          title: accessStatus.content.title,
          description: accessStatus.content.description,
          price: accessStatus.content.price.toString(),
          preview: accessStatus.content.preview,
        },
        paymentRequired: {
          tokenAddress: accessStatus.paymentRequired!.tokenAddress,
          amount: accessStatus.paymentRequired!.amount.toString(),
          recipient: accessStatus.paymentRequired!.recipient,
          contentId: accessStatus.paymentRequired!.contentId,
          facilitatorUrl: accessStatus.paymentRequired!.facilitatorUrl,
        },
      });
    } catch (error) {
      console.error("Error processing content request:", error);
      return res.status(500).json({
        error: "Internal server error",
        message: "Failed to process content request",
      });
    }
  });

  /**
   * GET /api/content
   * List all available content (public metadata only)
   */
  router.get("/", async (req: Request, res: Response) => {
    try {
      const contentList = Array.from(contentStore.values()).map((content) => ({
        id: content.id,
        title: content.title,
        description: content.description,
        price: content.price.toString(),
        preview: content.preview,
        metadata: content.metadata,
      }));

      return res.status(200).json({
        content: contentList,
        total: contentList.length,
      });
    } catch (error) {
      console.error("Error listing content:", error);
      return res.status(500).json({
        error: "Internal server error",
        message: "Failed to list content",
      });
    }
  });

  return router;
}
