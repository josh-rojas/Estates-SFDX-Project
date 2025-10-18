import { createElement } from "lwc";
import CaseHierarchyViewer from "c/caseHierarchyViewer";

// Mock NavigationMixin
const mockNavigate = jest.fn();
jest.mock(
  "lightning/navigation",
  () => {
    return {
      NavigationMixin: (Base) => {
        return class extends Base {
          [Symbol.for("Navigate")](config) {
            mockNavigate(config);
          }
        };
      }
    };
  },
  { virtual: true }
);

describe("c-case-hierarchy-viewer", () => {
  afterEach(() => {
    // Reset DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    // Reset mocks
    jest.clearAllMocks();
    mockNavigate.mockClear();
  });

  it("renders without errors", () => {
    const element = createElement("c-case-hierarchy-viewer", {
      is: CaseHierarchyViewer
    });
    element.recordId = "500xx000000001AAA";
    document.body.appendChild(element);

    // Verify component renders
    const card = element.shadowRoot.querySelector("lightning-card");
    expect(card).not.toBeNull();
  });

  it("has configurable properties", () => {
    const element = createElement("c-case-hierarchy-viewer", {
      is: CaseHierarchyViewer
    });
    element.recordId = "500xx000000001AAA";
    element.cardTitle = "Test Hierarchy";
    element.showFinancialAccounts = false;
    document.body.appendChild(element);

    // Verify properties are set
    expect(element.cardTitle).toBe("Test Hierarchy");
    expect(element.showFinancialAccounts).toBe(false);
  });

  it("has recordId property set", () => {
    const element = createElement("c-case-hierarchy-viewer", {
      is: CaseHierarchyViewer
    });
    element.recordId = "500xx000000001AAA";
    document.body.appendChild(element);

    // Verify recordId is set (public @api property)
    expect(element.recordId).toBe("500xx000000001AAA");
  });
});
