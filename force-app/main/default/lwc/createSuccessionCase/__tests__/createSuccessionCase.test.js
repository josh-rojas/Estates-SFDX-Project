/**
 * Jest tests for createSuccessionCase LWC component
 *
 * Tests Quick Action functionality including loading, error, and success states.
 */
import { createElement } from "lwc";
import CreateSuccessionCase from "c/createSuccessionCase";
import createSuccessionCase from "@salesforce/apex/CreateSuccessionCaseController.createSuccessionCase";

// Mock Apex method
jest.mock(
  "@salesforce/apex/CreateSuccessionCaseController.createSuccessionCase",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

const mockNavigate = jest.fn();
jest.mock(
  "lightning/navigation",
  () => {
    const NavigationMixin = (Base) => {
      return class extends Base {
        [NavigationMixin.Navigate] = mockNavigate;
      };
    };
    NavigationMixin.Navigate = Symbol("Navigate");
    return { NavigationMixin };
  },
  { virtual: true }
);

describe("c-create-succession-case", () => {
  afterEach(() => {
    // Reset DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    // Reset mocks
    jest.clearAllMocks();
  });

  it("renders component without calling Apex until invoke()", () => {
    const element = createElement("c-create-succession-case", {
      is: CreateSuccessionCase
    });
    element.recordId = "a0012345678901";

    // Mock pending promise
    createSuccessionCase.mockReturnValue(new Promise(() => {}));

    document.body.appendChild(element);

    // Verify Apex method was NOT called until invoke()
    expect(createSuccessionCase).not.toHaveBeenCalled();
  });

  it("handles successful case creation", () => {
    const element = createElement("c-create-succession-case", {
      is: CreateSuccessionCase
    });
    element.recordId = "a0012345678901";

    // Mock successful response
    const mockResult = {
      success: true,
      message: "Case created successfully",
      seedCaseId: "5001234567890",
      successorCount: 1
    };
    createSuccessionCase.mockResolvedValue(mockResult);

    document.body.appendChild(element);

    // Call invoke() method
    element.invoke();

    // Verify Apex was called
    expect(createSuccessionCase).toHaveBeenCalledWith({
      financialAccountId: "a0012345678901"
    });
  });

  it("handles error response from Apex", () => {
    const element = createElement("c-create-succession-case", {
      is: CreateSuccessionCase
    });
    element.recordId = "a0012345678901";

    // Mock error response
    const mockResult = {
      success: false,
      message: "A succession case already exists for this financial account"
    };
    createSuccessionCase.mockResolvedValue(mockResult);

    document.body.appendChild(element);

    // Call invoke() method
    element.invoke();

    // Verify error is handled
    return Promise.resolve().then(() => {
      expect(createSuccessionCase).toHaveBeenCalled();
    });
  });

  it("handles Apex exception", () => {
    const element = createElement("c-create-succession-case", {
      is: CreateSuccessionCase
    });
    element.recordId = "a0012345678901";

    // Mock Apex exception
    const mockError = {
      body: { message: "System.QueryException: List has no rows" },
      message: "System.QueryException"
    };
    createSuccessionCase.mockRejectedValue(mockError);

    document.body.appendChild(element);

    // Call invoke() method
    element.invoke();

    // Verify error is handled gracefully
    return Promise.resolve().then(() => {
      expect(createSuccessionCase).toHaveBeenCalled();
    });
  });

  it("supports invoke() method for Quick Action", () => {
    const element = createElement("c-create-succession-case", {
      is: CreateSuccessionCase
    });
    element.recordId = "a0012345678901";

    // Mock successful response
    const mockResult = {
      success: true,
      message: "Case created successfully",
      seedCaseId: "5001234567890",
      successorCount: 1
    };
    createSuccessionCase.mockResolvedValue(mockResult);

    document.body.appendChild(element);

    // Clear mock to start fresh
    createSuccessionCase.mockClear();

    // Call invoke() method
    element.invoke();

    // Verify Apex method was called again
    expect(createSuccessionCase).toHaveBeenCalledWith({
      financialAccountId: "a0012345678901"
    });
  });

  it("has recordId property exposed via @api", () => {
    const element = createElement("c-create-succession-case", {
      is: CreateSuccessionCase
    });

    element.recordId = "test123";
    expect(element.recordId).toBe("test123");
  });

  it("navigates to parent case for multi-successor scenario", () => {
    const element = createElement("c-create-succession-case", {
      is: CreateSuccessionCase
    });
    element.recordId = "a0012345678901";

    const mockResult = {
      success: true,
      message: "Cases created successfully",
      parentCaseId: "500PARENT123",
      seedCaseId: "500CHILD456",
      successorCount: 3
    };
    createSuccessionCase.mockResolvedValue(mockResult);

    document.body.appendChild(element);

    element.invoke();

    return Promise.resolve().then(() => {
      expect(mockNavigate).toHaveBeenCalledWith({
        type: "standard__recordPage",
        attributes: {
          recordId: "500PARENT123",
          objectApiName: "Case",
          actionName: "view"
        }
      });
    });
  });

  it("navigates to seed case for single-successor scenario", () => {
    const element = createElement("c-create-succession-case", {
      is: CreateSuccessionCase
    });
    element.recordId = "a0012345678901";

    const mockResult = {
      success: true,
      message: "Case created successfully",
      seedCaseId: "500SINGLE789",
      successorCount: 1
    };
    createSuccessionCase.mockResolvedValue(mockResult);

    document.body.appendChild(element);

    element.invoke();

    return Promise.resolve().then(() => {
      expect(mockNavigate).toHaveBeenCalledWith({
        type: "standard__recordPage",
        attributes: {
          recordId: "500SINGLE789",
          objectApiName: "Case",
          actionName: "view"
        }
      });
    });
  });
});
