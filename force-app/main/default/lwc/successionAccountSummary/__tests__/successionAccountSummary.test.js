import { createElement } from "lwc";
import SuccessionAccountSummary from "c/successionAccountSummary";

describe("c-succession-account-summary", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  // Helper to create complete caseContext for rendering
  const createMockCaseContext = (overrides = {}) => {
    return {
      deceasedDonorName: "John Smith",
      financialAccountName: "DAF Account #12345",
      financialAccountNumber: "12345",
      accountBalance: 250000,
      dateOfDeath: "2024-06-15",
      ...overrides
    };
  };

  it("renders without errors with complete caseContext", () => {
    const element = createElement("c-succession-account-summary", {
      is: SuccessionAccountSummary
    });
    element.caseContext = createMockCaseContext();
    document.body.appendChild(element);

    expect(element).toBeTruthy();
  });

  it("has caseContext as @api property", () => {
    const element = createElement("c-succession-account-summary", {
      is: SuccessionAccountSummary
    });
    const mockContext = createMockCaseContext();
    element.caseContext = mockContext;
    document.body.appendChild(element);

    expect(element.caseContext).toEqual(mockContext);
  });

  it("renders with large balance value", () => {
    const element = createElement("c-succession-account-summary", {
      is: SuccessionAccountSummary
    });
    element.caseContext = createMockCaseContext({ accountBalance: 5000000.99 });
    document.body.appendChild(element);

    expect(element).toBeTruthy();
  });

  it("renders with null balance", () => {
    const element = createElement("c-succession-account-summary", {
      is: SuccessionAccountSummary
    });
    element.caseContext = createMockCaseContext({ accountBalance: null });
    document.body.appendChild(element);

    expect(element).toBeTruthy();
  });

  it("renders with null date of death", () => {
    const element = createElement("c-succession-account-summary", {
      is: SuccessionAccountSummary
    });
    element.caseContext = createMockCaseContext({ dateOfDeath: null });
    document.body.appendChild(element);

    expect(element).toBeTruthy();
  });
});
